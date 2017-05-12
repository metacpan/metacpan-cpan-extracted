package Template::Plugin::ScalarUtil;
BEGIN {
  $Template::Plugin::ScalarUtil::AUTHORITY = 'cpan:AJGB';
}
{
  $Template::Plugin::ScalarUtil::VERSION = '1.121160';
}
# ABSTRACT: Scalar::Util plugin for Template-Toolkit

use strict;
use warnings;

use base qw( Template::Plugin );

use Scalar::Util qw();


{
    no strict 'refs';

    do {
        my $func = $_;

        my $call = Scalar::Util->can($func)
            or die "$func not exported by Scalar::Util";

        *{__PACKAGE__ ."::$func"} = sub {
            shift @_;

            $call->(@_);
        }
    } for qw(
        blessed dualvar reftype tainted
        openhandle refaddr isvstring looks_like_number
    );

};

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Template::Plugin::ScalarUtil - Scalar::Util plugin for Template-Toolkit

=head1 VERSION

version 1.121160

=head1 SYNOPSIS

    [% USE ScalarUtil %]

    # blessed
    [% ScalarUtil.blessed(EXPR) ? 'blessed' : 'not blessed' %]

    # dualvar
    [% SET dv = ScalarUtil.dualvar( 5, "Hello" ) %]
    [% SET num = dv + 7 %]
    [% SET string = dv _ " world!" %]
    [% num == string.length ? "correct" : "ups" %]

    # isvstring
    [% ScalarUtil.isvstring(vstring) ? 'is vstring' : 'is not vstring' %]

    # looks_like_number
    [% ScalarUtil.looks_like_number('Infinity') ? 'number' : 'not number' %]

    # openhandle
    [% ScalarUtil.openhandle(FH) ? "opened" : "not opened" %]

    # refaddr
    [% ScalarUtil.refaddr(EXPR) %]

    # reftype
    [% ScalarUtil.reftype(EXPR) %]

    # tainted
    [% ScalarUtil.tainted(EXPR) %]

=head1 DESCRIPTION

Use L<Scalar::Util> functions in your templates.

=head1 METHODS

=head2 blessed

    [%
        IF ScalarUtil.blessed(EXPR);
            EXPR.method(args);
        END;
    %]

Returns the name of the package if C<EXPR> is a blessed reference.

=head2 dualvar

    [% SET dv = ScalarUtil.dualvar( num, string ) %]

Returns a scalar that has the value C<num> in a numeric context and the value
C<string> in a string context.

=head2 isvstring

    [%
        USE vstring = format('%vd');
        USE string = format('%s');

        IF ScalarUtil.isvstring(EXPR);
            vstring(EXPR);
        ELSE;
            string(EXPR);
        END;
    %]

Returns true if C<EXPR> was coded as vstring;

=head2 looks_like_number

    [% IF ScalarUtil.looks_like_number(EXPR) %]
        [% EXPR %] looks like number
    [% END %]

Returns true if perl thinks C<EXPR> is a number.

=head2 openhandle

    [% IF ScalarUtil.openhandle(FH) %]
        FH is an opened filehandle
    [% END %]

Returns C<FH> if it is opened filehandle, C<undef> otherwise.

=head2 refaddr

    [% ScalarUtil.refaddr(EXPR) %]

Returns internal memory address of the C<EXPR> if it is a reference, C<undef>
otherwise.

=head2 reftype

    [% SWITCH ScalarUtil.reftype(EXPR) %]
        [% CASE 'ARRAY' %]
            [% EXPR.size %]
        [% CASE 'HASH' %]
            [% EXPR.list.size %]
    [% END %]

Returns the type of the C<EXPR> if it is a reference, C<undef> otherwise.

=head2 tainted

    [% IF ScalarUtil.tainted(EXPR) %]
        EXPR is tainted
    [% END %]

Returns true if C<EXPR> is tainted.

=head1 NOTES

Please note that following methods were B<NOT> implemented due to the nature
of TT's stash.

=over 4

=item * isweak

=item * readonly

=item * set_prototype

=item * weaken

=back

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Scalar::Util>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

