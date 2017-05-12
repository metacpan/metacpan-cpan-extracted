package Net::LCDproc::Error;
$Net::LCDproc::Error::VERSION = '0.104';
#ABSTRACT: Error class

use v5.10.2;
use Data::Dumper qw//;
use Moo;
use namespace::clean;

extends 'Throwable::Error';

has class_name => (
    is => 'rw',

    #isa      => 'Str',
    required => 1,
    default  => sub { caller 11 },    # XXX: this seems fragile

);

has object => (
    is => 'ro',

    #isa       => 'Object',
    predicate => 'has_object',
);

sub short_msg {
    my $self = shift;
    return sprintf '[%s] %s', $self->class_name, $self->message;
}

sub dump_obj {
    my $self = shift;

    if ($self->has_object) {
        $Data::Dumper::Terse = 1;
        return Data::Dumper->Dump([$self->object]);
    }

    return 'No object was set by the throwing class';
}

sub throwf {
    my ($self, $msg_str, @args) = @_;
    $self->throw(message => sprintf $msg_str, @args);
    return;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Ioan Rogers

=head1 NAME

Net::LCDproc::Error - Error class

=head1 VERSION

version 0.104

=head1 SYNOPSIS

  use Net::LCDproc;
  use Try::Tiny;

  my $lcdproc = Net::LCDproc->new( server => 'no_such_host', port => 1234 );

  try {
      $lcdproc->init;
  }
  catch {
      #die $_->message;
      #die $_->dump;
      #die $_->short_msg;
      die $_;
  };

=head1 DESCRIPTION

L<Throwable::Error|Throwable::Error> based exception class. You should probably
read its documentation first, then come back here.

When C<Net::LCDproc> encounters an error, it will throw an exception you can catch, or not.

By default C<Throwable::Error> will provide the error message with a stack trace.
This module offers a few other options for you to choose from.

=head1 ATTRIBUTES

=over

=item C<class_name>

B<Required>. A string containing the name of the throwing class.

=item C<object>

Any blessed object, usually a copy of the throwing class' C<$self>.

=back

=head1 METHODS

=over

=item C<short_msg>

Returns a string containing the C<class_name> and the C<message>.

=item C<dump>

Returns a stringified C<< $self->object >>, using L<Data::Dumper|Data::Dumper>. If C<< $self->object >>
isn't set, returns a string saying so.

=back

=head1 SEE ALSO

Throwable::Error

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/ioanrogers/Net-LCDproc/issues>.

=head1 AVAILABILITY

The project homepage is L<http://metacpan.org/release/Net-LCDproc/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Net::LCDproc/>.

=head1 SOURCE

The development version is on github at L<http://github.com/ioanrogers/Net-LCDproc>
and may be cloned from L<git://github.com/ioanrogers/Net-LCDproc.git>

=head1 AUTHOR

Ioan Rogers <ioanr@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Ioan Rogers.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
