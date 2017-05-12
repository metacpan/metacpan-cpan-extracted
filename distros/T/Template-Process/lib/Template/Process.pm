
package Template::Process;

use 5;
use strict;
use warnings;

our $VERSION = '0.0006';
$VERSION = eval $VERSION;

use base qw(Class::Accessor);
Template::Process->mk_accessors(qw(tt));

use Carp qw(carp croak);
use Template;
use Data::IO;

sub new {
    return shift->SUPER::new({ tt => Template->new });
}

=begin private

=item B<_process>

    $tt->_process(TT => $tt, DATA => \@hashes, OUT => $handle);

=end private

=cut

sub _process {
    my $self = shift;
    my %args = @_;
#    warn YAML::Dump \%args;
    my $tt = $args{TT};
    my $out = $args{OUT} || \*STDOUT;
    my @data;
    @data = ref $args{DATA} ?  @{$args{DATA}} : ($args{DATA});
    my %data;
    %data = (%data, %$_) for @data;
    return $self->tt->process($tt, \%data, $out);
}

sub _io { # this works only for $] >= 5.8
    open my $io, '>', shift
        or croak "can't open in-core file: $!";
    return $io;
}

sub process {
    my $self = shift;
    my %args = @_;
#    warn YAML::Dump \%args;
    my $tt = $args{TT};
    my $reader = Data::IO->new;

    my @data;
    my @args = defined $args{DATA} ?
               (ref $args{DATA} ? @{$args{DATA}} : ($args{DATA})) :
               ();
    for (@args) {
        if (ref $_) { # perl data already
            push @data, $_;
        } elsif (-f && /\.ya?ml$/) {
            push @data, $reader->_read_yaml($_);
        } elsif (-f && /\.PL$/i) {
            push @data, $reader->_read_perl($_);
        } else {
            carp "'$_' ignored: unkown format\n";
        }
    }

    my $out = $args{OUT};
    $out = _io($out) if (ref $out eq 'SCALAR');
    $out = \*STDOUT unless $out;
    
    return $self->_process(TT => $tt, DATA => \@data, OUT => $out);

}

sub error { return shift->tt->error }

1;

__END__
=head1 NAME

Template::Process - Process TT2 templates against data files

=head1 SYNOPSIS

  use Template::Process;
  $tt = Template::Process->new();
                                # VARS
  $tt->process(TT => 'h.tt.html', DATA => 'vars.yml', OUT => 'h.html')
      or die $tt->error;

=head1 DESCRIPTION

This module implements a facility to process TT2
scripts against data files, so that applying
simple templates to simple data involves no
coding.

This is the heart of the B<tt> script (which comes
in the same distribution).

=head2 METHODS

=over 4

=item B<new>

    $tt = Template::Process->new;

The constructor.

=item B<process>

    $tt->process(TT => $tt, DATA => \@data, OUT => $out);

The elements at C<@data> may be: hash refs, YAML and Perl filenames. 
A YAML filename is expected to exist (C<-f $_> returns true) 
and match C</\.ya?ml$/>. A Perl filename must satisfy C<-f $_>
and match C</\.PL$/>.

If C<DATA> is ommitted, the template is processed with no
extra variables.

If C<OUT> is ommitted, C<\*STDOUT> is used.

=item B<error>

    $tt->process(@ARGS) or
        die $tt->error;

In case of processing errors, returns a (hopefully) helpful message.

=back

=head2 EXPORT

None at all. This is OO.

=head1 SEE ALSO

  ttree (from Template-Toolkit distribution)

=head1 AUTHOR

Adriano Ferreira, E<lt>ferreira@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2006-2007 by Adriano Ferreira

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
