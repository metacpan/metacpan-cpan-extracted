package Module::Require;

use strict;
use vars qw: @ISA @EXPORT_OK $VERSION :;

$VERSION = '0.05';

@ISA = qw[ Exporter ];

# $Id: Require.pm,v 1.1 2004/03/05 16:58:44 jgsmith Exp $

@EXPORT_OK = qw: require_regex require_glob walk_inc :;

sub _walk_inc {
    my $filter = shift;
    my $todo = shift;
    my $prefix = shift;
    my $root = shift;

    my %modules = ( );
    my $dh;
    opendir $dh, "$prefix/$root";
    my(@files) = grep { defined } map &$filter("$root/$_"), grep !/^\./, readdir($dh);
    closedir $dh;
    foreach my $f (@files) {
        next unless $f;
        my $realfilename = "$prefix/$root/$f";
        next if $INC{"$root/$f"};
        if ( -d $realfilename ) {
            @modules{&_walk_inc($filter, $todo, $prefix, "$root/$f")} = ( );
        } elsif( -f $realfilename ) {
            $modules{"$root/$f"} = undef;
            eval { &$todo("$root/$f", $realfilename) and delete $modules{"$root/$f"} };
        }
    }
    return keys %modules;
}

sub walk_inc(;&&$) {
    my $filter = shift;
    $filter ||= sub { return $_ unless /\.pod$/ or /\.pl$/ };

    my $todo = shift;
    $todo ||= sub { require $_[1] and $INC{$_[0]} = $_[1] and 1 };

    my $root = shift;
    $root = "" unless defined $root;

    my %modules = ( );
    foreach my $prefix (@INC) {
        @modules{_walk_inc $filter, $todo, $prefix, $root} = ( );
    }
    return unless defined wantarray;
    return wantarray ? keys %modules : scalar keys %modules;
}

sub require_regex {
    my %modules = ( );
    while(@_) {
        my $file = shift;
        $file =~ s{::}{/}g;
        $file .= ".pm";
        my $fileprefix = "";

        if($file =~ m{^(.*)/([^/]*)$}) {
            $fileprefix = $1;
            $file = $2;
        }

        # $file is guaranteed to not have a `/' in it :)
        my $filter = eval qq"sub { grep m/$file/, readdir \$_[0] }";

        # thanks to `perldoc -f require' for the basic logic here :)
        foreach my $prefix (@INC) {
            my $dh;
            opendir $dh, "$prefix/$fileprefix";
            my @files = &$filter($dh);
            closedir $dh;
            foreach my $f (@files) {
                my $realfilename = "$prefix/$fileprefix/$f";
                next if $INC{$realfilename} || $INC{"$fileprefix/$f"};
                if( -f $realfilename ) {
                    $modules{"$fileprefix/$f"} = undef;
                    eval {
                        $INC{"$fileprefix/$f"} = $realfilename if eval qq"require $realfilename";
			delete $INC{$realfilename};
                    };
                }
            }
        }
        delete @modules{grep m{$fileprefix/$file}, keys %INC} if defined wantarray;
    }
    return unless defined wantarray;
    return wantarray ? keys %modules : scalar keys %modules;
}

sub require_glob {
    my %modules = ( );
    while(@_) {
        my $file = shift;
        $file =~ s{::}{/}g;
        $file .= '\.pm';
        my $fileprefix = "";

        if($file =~ m{^(.*)/([^/]*)$}) {
            $fileprefix = $1;
            $file = $2;
        }

        # thanks to `perldoc -f require' for the basic logic here :)
        foreach my $prefix (@INC) {
            my @files = eval "<$prefix/$fileprefix/$file>";
            foreach my $realfilename (@files) {
                my $f = $realfilename;
                $f =~ s{^$prefix/$fileprefix/}{};
                next if $INC{$realfilename} || $INC{"$fileprefix/$f"};
                if( -f $realfilename ) {
                    $modules{"$fileprefix/$f"} = undef;
                    eval {
                        if(eval { require $realfilename }) {
                            $INC{"$fileprefix/$f"} = $realfilename;
                            delete $modules{"$fileprefix/$f"};
			    delete $INC{$realfilename};
                        }
                    };
                }
            }
        }
    }
    return unless defined wantarray;
    return wantarray ? keys %modules : scalar keys %modules;
}

1;

__END__

=head1 NAME

Module::Require

=head1 SYNOPSIS

 use Module::Require qw: require_regex require_glob :;

 require_regex q[DBD::.*];
 require_regex qw[DBD::.* Foo::Bar_.*];
 require_glob qw[DBD::* Foo::Bar_*];
 walk_inc sub { m{(/|^)Bar_.*$} and return $_ }, undef, q"DBD";

=head1 DESCRIPTION

This module provides a way to load in a series of modules without having to
know all the names, but just the pattern they fit.  This can be useful for
allowing drop-in modules for application expansion without requiring
configuration or prior knowledge.

The regular expression and glob wildcards can only match the filename of
the module, not the directory in which it resides.  So, for example,
C<Apache::*> will load all the modules that begin with C<Apache::>,
including C<Apache::Session>, but will not load C<Apache::Session::MySQL>.
Likewise, C<*::Session> is not allowed since the variable part of the
module name is not in the last component.

Note that unlike the Perl C<require> keyword, quoting or leaving an
argument as a bareword does not affect how the function behaves.

=head1 FUNCTIONS

=over 4

=item walk_inc \&filter \&todo 'path'

This function will walk through C<@INC> and pass each filename under
"path::" to C<&filter>.  If C<&filter> returns a defined value, the
returned value is then passed to the C<&todo> function.  The default path
is '' (the empty string).  The default filter function is to return the
argument.  The default todo function is to load the module.

For example,

  print join "\n", walk_inc;

will try to load all the available modules, printing a list of modules that
could not be loaded.  Note that files and directories beginning with a
period (`.') are not considered.

  walk_inc sub { /^X/ and return $_ }, undef, 'Foo';

will try and load all the modules in the C<Foo::> namespace that begin with
an `X', recursively.

Module files should end with C<.pm> and directories otherwise.  This allows
for an easy way to keep C<walk_inc> from descending directories.  The
filter function may also be used to transform module names.

If the module is already in C<%INC> it will be passed over.

=item require_regex

This function takes a list of files and searches C<@INC> trying to find all
possible modules.  Only the last part of the module name should be the
regex expression (C<Foo::Bar_.*> is allowed, but C<F.*::Bar> is not).  Each
file found and successfully loaded is added to C<%INC>.  Any file already
in C<%INC> is not loaded.  No C<import> functions are called.

The function will return a list of files found but not loaded or, in a
scalar context, the number of such files.  This is the opposite of the
sense of C<require>, with true meaning at least one file failed to load.

=item require_glob

This function behaves the same as the C<require_regex> function except it
uses the glob operator (E<lt>E<gt>) instead of regular expressions.

=back 4

=head1 SEE ALSO

perldoc -f require.

=head1 AUTHOR

James G. Smith <jsmith@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2001, 2004 Texas A&M University.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

