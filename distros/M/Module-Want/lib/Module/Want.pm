package Module::Want;

use strict;
*normalize_ns            = \&get_clean_ns;    # do before warnings to prevent 'only used once' warning
*get_relative_path_of_ns = \&get_inc_key;     # do before warnings to prevent 'only used once' warning
use warnings;

$Module::Want::VERSION = '0.6';

my %lookup;

# Uncomment these 3 lines and '        # $tries{$ns}++;' in have_mod() for dev testing
# $Module::Want::DevTesting = 1;
# my %tries;
# sub _get_debugs_refs { return \%lookup, \%tries }

my $ns_regexp = qr/[A-Za-z_][A-Za-z0-9_]*(?:(?:\:\:|\')[A-Za-z0-9_]+)*/;

sub get_ns_regexp { return $ns_regexp }

sub is_ns { $_[0] =~ m/\A$ns_regexp\z/ }

sub get_all_use_require_in_text {
    return $_[0] =~ m/(?:^\s*|\;\s*|eval[^;]+)(?:use|require)\s+($ns_regexp)/g;
}

sub get_inc_key {
    return if !is_ns( $_[0] );

    # %INC keys are always unix format so no need for File::Spec
    #   if I've been misinformed of that fact then please let me know, thanks
    my $key = $_[0] . '.pm';
    $key =~ s{(?:\:\:|\')}{/}g;
    return $key;
}

sub distname2ns {
    my ($node) = @_;
    $node =~ s/-/::/g;
    my $ns = get_clean_ns($node);
    return $ns if is_ns($ns);
    return;
}

sub ns2distname {
    my $node = get_clean_ns( $_[0] );
    return if !is_ns($node);
    $node =~ s/::/-/g;
    return $node;
}

sub get_clean_ns {
    my $dirty = $_[0];
    $dirty =~ s{^\s+}{};
    $dirty =~ s{\s+$}{};
    $dirty =~ s{\'}{::}g;
    return $dirty;
}

sub have_mod {
    my ( $ns, $skip_cache ) = @_;
    $skip_cache ||= 0;

    if ( !is_ns($ns) ) {
        require Carp;
        Carp::carp('Invalid Namespace');
        return;
    }

    if ( $skip_cache || !exists $lookup{$ns} ) {

        $lookup{$ns} = 0;

        #        $tries{$ns}++;
        local $SIG{__DIE__};                       # prevent benign eval from tripping potentially fatal sig handler
        eval qq{require $ns;\$lookup{\$ns}++;};    ## no critic
    }

    return $lookup{$ns} if $lookup{$ns};
    return;
}

sub get_inc_path_via_have_mod {
    my ( $ns, $skip_cache ) = @_;
    return unless have_mod( $ns, $skip_cache );
    return $INC{ get_inc_key($ns) };
}

sub search_inc_paths {
    my ( $ns, $want_abs ) = @_;

    have_mod('File::Spec') || return;

    my $rel_path = File::Spec->catfile( split( m{/}, get_relative_path_of_ns($ns) ) );
    my $return_first = wantarray ? 0 : 1;
    my @result;

    for my $path (@INC) {
        my $abspath = File::Spec->rel2abs( $rel_path, $path );
        if ( -f $abspath ) {
            push @result, ( $want_abs ? $abspath : $path );
            last if $return_first;
        }
    }

    if (@result) {
        return $result[0] if $return_first;
        return @result;
    }
    return;
}

sub import {
    shift;

    my $caller = caller();

    no strict 'refs';    ## no critic
    *{ $caller . '::have_mod' } = \&have_mod;

    for my $ns (@_) {
        next if $ns eq 'have_mod';

        if ( $ns eq 'is_ns' || $ns eq 'get_inc_key' || $ns eq 'get_clean_ns' || $ns eq 'get_ns_regexp' || $ns eq 'get_all_use_require_in_text' || $ns eq 'get_relative_path_of_ns' || $ns eq 'normalize_ns' || $ns eq 'get_inc_path_via_have_mod' || $ns eq 'search_inc_paths' || $ns eq 'distname2ns' || $ns eq 'ns2distname' ) {
            *{ $caller . "::$ns" } = \&{$ns};
        }
        else {
            have_mod($ns);
        }
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Module::Want - Check @INC once for modules that you want but may not have

=head1 VERSION

This document describes Module::Want version 0.6

=head1 SYNOPSIS

    use Module::Want;

    if (have_mod('Encode')) {
        ... use Encode::whatever ...
    }
    else {
        ... use Encode:: alternative ...
    }

=head1 DESCRIPTION

Sometimes you want to lazy load a module for use in, say, a loop or function. First you do the eval-require but then realize if the module is not available it will re-search @INC each time. So then you add a lexical boolean to your eval and do the same simple logic all over the place. On and on it goes :)

This module encapsulates that logic so that have_mod() is like eval { require X; 1 } but if the module can't be loaded it will remember that fact and not look in @INC again on subsequent calls.

For example, this searches @INC for X.pm every iteration of the loop:

    while( ... ) {
        if (eval { require X; 1 }) {
            ... use X code ...
        }
        else {
            ... do X-alternative code ...
        }
    }

This searches @INC for X.pm once:
    
    while( ... ) {
        if (have_mod('X')) {
            ... use X code ...
        }
        else {
            ... do X-alternative code ...
        }
    }

Additionally, it will not trip the sig die handler. That prevents a benign eval from tripping a potentially fatal sig handler. (i.e. another step you'd have to do manually with the straight eval form.)

=head1 INTERFACE 

import() puts have_mod() into the caller's name space.

=head2 have_mod()

Takes the name space to require() if we have not tried already.

Returns true if it could be loaded. False otherwise.

You can give it a second true argument to skip using the value from the last time it was called and re-try require()ing it.

   if (!have_mod('X')) {
       # do some things to try and ger X available 
   }
   
   if (have_mod('X',1)) {
       # sweet we have it now!
   }

=head2 import()

You can use() it with a list to call have_mod() on:

   use Module::Want qw(X Y Z); # calls have_mod('X'), have_mod('Y'), and have_mod('Z')

=head2 Utility functions

These aren't the real reasons for this module but they've proven useful when you're doing things that would require have_mod() so here they are:

They can all be exported thusly:

    use Module::Want qw(is_ns);

For an entire suite if name space utilities see L<Module::Util> and friends.

=head3 is_ns($ns)

Boolean of if '$ns' is a proper name space or not.

    if(is_ns($ns)) {
        ... use $ns as a module/class name ...
    }
    else {
       ... "invalid input please try again" prompt ...
    }

=head3 get_ns_regexp()

Returns a quoted Regexp that matches a name space for use in your regexes.

=head3 get_all_use_require_in_text($text)

This will return a list of all name spaces being use()d or require()d in perlish looking $text.

It will also return ones being eval()d in.

It is very simplistic (e.g. it may or may not return use/require statements that are in comments, it will match verbiage in a here doc that start w/ “use”) so if it does not fit your needs you'll need to try a L<PPI> based solution (I have L<Perl::DependList> on my radar that does just that.). 

=head3 get_inc_key($ns) 

Returns what $ns's key in %INC would be (if is_ns($ns) of course)

    if (my $inc_key =  get_inc_key($ns)) {
        if (exists $INC{$inc_key}) {
           ... in %INC ...
        }
        else {
            ... not in %INC ...
        }    
    }

%INC keys are always unix format so don't panic

If I've been misinformed of that fact then please let me know, thanks

=head4 get_relative_path_of_ns($ns)

Alias of L</get_inc_key($ns)> whose name indicates a different intent.

=head3 get_clean_ns($ns)

Takes $ns, trims leading and trailing whitespace and turns ' into ::, and returns the cleaned copy.

=head4 normalize_ns($ns)

Alias of L</get_clean_ns($ns)> whose name indicates a different intent.

=head3 ns2distname($ns)

Turns the given name space into a distribution name.

e.g. Foo::Bar::Baz becomes Foo-Bar-Baz

=head3 distname2ns($distname)

Turns the given distribution name into a name space.

e.g. Foo-Bar-Baz becomes Foo::Bar::Baz

=head3 get_inc_path_via_have_mod($ns)

Return the %INC entry’s value if we have_mod($ns);

=head3 search_inc_paths($ns)

Without loading the module, search for $ns in @INC.

In scalar context returns the first path it is found in, in list context returns all paths it is found in.

    my $first_path_it_is_in = search_inc_paths($ns);
    my @all_paths_it_is_in  = search_inc_paths($ns);

By default it returns the path it is in without the module-name part of the path. A second true argument will return the entire path.

    my $abs_path_of_pm_file = search_inc_paths($ns,1);

=head1 DIAGNOSTICS

=over

=item C<< Invalid Namespace >>

The argument to have_mod() is not a name space

=back

=head1 CONFIGURATION AND ENVIRONMENT

Module::Want requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-want@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
