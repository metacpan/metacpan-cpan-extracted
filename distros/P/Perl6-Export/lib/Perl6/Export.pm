package Perl6::Export;
our $VERSION = '0.009';

my $ident   = qr{ [^\W\d] \w* }x;
my $arg     = qr{ : $ident \s* ,? \s* }x;
my $args    = qr{ \s* \( $arg* \) | (?# NOTHING) }x;
my $defargs = qr{ \s* \( $arg* :DEFAULT $arg* \) }x;
my $proto   = qr{ \s* (?: \( [^)]* \) | (?# NOTHING) ) }x;

sub add_to {
    my ($EXPORT, $symbol, $args, $decl) = @_;
    $args = "()" unless $args =~ /\S/;
    $args =~ tr/://d;
    return  q[BEGIN{no strict 'refs';]
         .  q[use vars qw(@EXPORT @EXPORT_OK %EXPORT %EXPORT_TAGS );]
         . qq[push\@$EXPORT,'$symbol';\$EXPORT{'$symbol'}=1;]
         . qq[push\@{\$EXPORT_TAGS\{\$_}},'$symbol' for ('ALL',qw$args)}$decl];
}

sub false_import_sub {
    my $import_sub = q{
        use base 'Exporter';
        use vars qw(@EXPORT @EXPORT_OK %EXPORT %EXPORT_TAGS );
        sub import {
            my @exports;
            for (my $i=1; $i<@_; $i++) {
                for ($_[$i]) {
                    if (!ref && /^[:\$&%\@]?(\w+)$/ && 
                        ( exists $EXPORT{$1} || exists $EXPORT_TAGS{$1}) ) {
                        push @exports, splice @_, $i, 1;
                        $i--;
                    }
                }
            }
            @exports = ":DEFAULT" unless @exports;
            __PACKAGE__->export_to_level(1, $_[0], ':MANDATORY', @exports); 
            goto &REAL_IMPORT;
        }
    };
    $import_sub =~ s/\n/ /g;
    $import_sub =~ s/REAL_IMPORT/$_[0]/g;
    return $import_sub;
}

my $MANDATORY = q[BEGIN{$EXPORT_TAGS{MANDATORY}||=[]}];

use Filter::Simple;
use Digest::MD5 'md5_hex';

FILTER {
    return unless /\S/;
    my $real_import_name = '_import_'.md5_hex($_);
    my $false_import_sub = false_import_sub($real_import_name);
    my $real_import_sub = "";
    s/ \b sub \s+ import \s* ([({]) /sub $real_import_name$1/x 
        or s/ IMPORT \s* ([{]) /sub $real_import_name$1/x 
        or $real_import_sub = "sub $real_import_name {}";
    s{( \b sub \s+ ($ident) $proto) \s+ is \s+ export ($defargs) }
     { add_to('EXPORT',$2,$3,$1) }gex;
    s{( \b our \s+ ([\$\@\%]$ident) $proto) \s+ is \s+ exported ($defargs) }
     { add_to('EXPORT',$2,$3,$1) }gex;
    s{( \b sub \s+ ($ident) $proto ) \s+ is \s+ export ($args) }
     { add_to('EXPORT_OK',$2,$3,$1) }gex;
    s{( \b our \s+ ([\$\@\%]$ident) ) \s+ is \s+ export ($args) }
     { add_to('EXPORT_OK',$2,$3,$1) }gex;
    $_ = $real_import_sub . $false_import_sub . $MANDATORY . $_;
}

__END__

=head1 NAME

Perl6::Export - Implements the Perl 6 'is export(...)' trait


=head1 SYNOPSIS

    # Perl 5 code...

    package Some::Module;
    use Perl6::Export;

    # Export &foo by default, when explicitly requested,
    # or when the ':ALL' export set is requested...

    sub foo is export(:DEFAULT) {
        print "phooo!";
    }


    # Export &bar by default, when explicitly requested,
    # or when the ':bees', ':pubs', or ':ALL' export set is requested...
    # the parens after 'is export' are like the parens of a qw(...)

    sub bar is export(:DEFAULT :bees :pubs) {
        print "baaa!";
    }


    # Export &baz when explicitly requested
    # or when the ':bees' or ':ALL' export set is requested...

    sub baz is export(:bees) {
        print "baassss!";
    }


    # Always export &qux 
    # (no matter what else is explicitly or implicitly requested)

    sub qux is export(:MANDATORY) {
        print "quuuuuuuuux!";
    }


    IMPORT {
        # This block is called when the module is used (as usual),
        # but it is called after any export requests have been handled.
        # Those requests will have been stripped from its @_ argument list
    }


=head1 DESCRIPTION

Implements what I hope the Perl 6 symbol export mechanism might look like.

It's very straightforward:

=over

=item *

If you want a subroutine to be capable of being exported (when
explicitly requested in the C<use> arguments), you mark it
with the C<is export> trait.

=item *

If you want a subroutine to be automatically exported when the module is
used (without specific overriding arguments), you mark it with
the C<is export(:DEFAULT)> trait.

=item *

If you want a subroutine to be automatically exported when the module is
used (even if the user specifies overriding arguments), you mark it with
the C<is export(:MANDATORY)> trait.

=item * 

If the subroutine should also be exported when particular export groups
are requested, you add the names of those export groups to the trait's
argument list.

=back

That's it.

=head2 C<IMPORT> blocks

Perl 6 replaces the C<import> subroutine with an C<IMPORT> block. It's
analogous to a C<BEGIN> or C<END> block, except that it's executed every
time the corresponding module is C<use>'d. 

Perl6::Export honours either the Perl5-ish:

    sub import {...}

or the equivalent Perl6-ish:

    IMPORT {...}

In either case the subroutine/block is passed the argument list that was
specified on the C<use> line that loaded the corresponding module. However,
any export specifications (names of subroutines or tagsets to be exported)
will have already been removed from that argument list before
C<import>/C<IMPORT> receives it.


=head1 WARNING

The syntax and semantics of Perl 6 is still being finalized
and consequently is at any time subject to change. That means the
same caveat applies to this module.


=head1 DEPENDENCIES

Requires Filter::Simple

=head1 AUTHOR

Damian Conway (damian@conway.org)


=head1 BUGS AND IRRITATIONS

Does not yet handle the export of variables. 
The author personally believes this is a feature, rather than a bug.

Comments, suggestions, and patches welcome.


=head1 COPYRIGHT

 Copyright (c) 2003, Damian Conway. All Rights Reserved.
 This module is free software. It may be used, redistributed
    and/or modified under the same terms as Perl itself.
