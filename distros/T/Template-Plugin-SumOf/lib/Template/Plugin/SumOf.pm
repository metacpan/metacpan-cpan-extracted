package Template::Plugin::SumOf;
use strict;
use warnings;
use base qw(Template::Plugin);
use Carp;
use Template::Stash;
use List::Util qw/sum/;
use Scalar::Util qw/blessed/;

use version;
our $VERSION = '0.03';

$Template::Stash::LIST_OPS->{sum_of} = sub {
    my ( $self, $column ) = @_;

    return sum map { blessed $_ ? $_->$column : $_->{$column} } @$self;
};

1;    # Magic true value required at end of module
__END__

=head1 NAME

Template::Plugin::SumOf - calculate the sum with VMETHODS.

=head1 SYNOPSIS

    # in your script
    use Template;
    use Template::Plugin::SumOf;
    my $tt = Template->new;
    $tt->process(
        'template.html',
        {
            ary => [
                { date => '2006-09-13', price => 300 },
                { date => '2006-09-14', price => 500 }
            ]
        }
      )
      or die $tt->error;

    # in your template.
    [% USE SumOf -%]
    [%- FOR elem IN objects -%]
    [% elem.date  %],[% elem.price %]
    [% END -%]
    ,[% objects.sum_of('price') %]

    # result.
    2006-09-13,300
    2006-09-14,500
    ,800

=head1 DESCRIPTION

You can easy to calculate sum of array, with VMETHODS.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-template-plugin-sumof@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Tokuhiro Matsuno  C<< <tokuhiro __at__ mobilefactory.jp> >>

=head1 SEE ALSO

L<Template>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Tokuhiro Matsuno C<< <tokuhirom @__at__ gmail.com> >>. All rights reserved.

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
