package Spoon::Template::Mason;

use strict;
use warnings;
use Spoon 0.23;
use Spoon::Template '-base';

use Cwd ();
use HTML::Mason::Interp;

use vars qw ($VERSION);

$VERSION = 0.05;

field 'interp' =>
      -init => '$self->_make_interp';

sub render
{
    my $self = shift;
    my $comp = shift;

    $comp = "/$comp" unless $comp =~ m{^/};

    my $output = '';
    $self->interp->out_method(\$output);
    $self->interp->exec( $comp, $self->all, @_ );

    return $output;
}

#method private make_interp => sub
sub _make_interp
{
    my $self   = shift;
    my $params = shift || {};

    my $root_name = 'root001';
    my $path = $self->path;
    my @roots = map { [ $root_name++ => Cwd::abs_path($_) ] } ref $path ? @$path : $path;

    my $interp =
        HTML::Mason::Interp->new
            ( comp_root => \@roots,
              %$params,
            );

    $self->interp($interp);
};


1;

__END__

=pod

=head1 NAME

Spoon::Template::Mason - A Spoon template module that uses Mason

=head1 SYNOPSIS

  # in your config.yaml file

  template_class: Spoon::Template::Mason

=head1 DESCRIPTION

So you like Spoon/Spork/Kwiki, but you want to use Mason to generate
your output.  This is the module for you.

=head1 USAGE

Just set "template_class" in your F<config.yaml> file to
C<Spoon::Template::Mason>.

=head1 SUPPORT

Support questions can be sent to me via email.

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=spoon-template-mason or
via email at bug-spoon-template-mason@rt.cpan.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

