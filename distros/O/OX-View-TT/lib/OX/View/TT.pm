package OX::View::TT;
BEGIN {
  $OX::View::TT::AUTHORITY = 'cpan:DOY';
}
$OX::View::TT::VERSION = '0.02';
use Moose;
# ABSTRACT: View wrapper class for TT renderers

use MooseX::Types::Path::Class;
use Template;


has 'template_root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

has 'template_config' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { +{} },
);

has 'tt' => (
    is      => 'ro',
    isa     => 'Template',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Template->new(
            INCLUDE_PATH => $self->template_root,
            %{ $self->template_config }
        )
    }
);

has template_params => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
);

sub _get_all_template_params {
    my ($self, $r, $params) = @_;
    return +{
        %{ $self->template_params },
        base    => $r->script_name,
        uri_for => sub { $r->uri_for(@_) },
        m       => $r->mapping,
        %{ $params || {} }
    }
}


sub render {
    my ($self, $r, $template, $params) = @_;
    my $out = '';
    $self->tt->process(
        $template,
        $self->_get_all_template_params( $r, $params ),
        \$out
    ) || confess $self->tt->error;
    $out;
}


sub template {
    my $self = shift;
    my ($r) = @_;

    my %params = %{ $r->mapping };
    confess("Must supply a 'template' parameter")
        unless exists $params{template};

    return $self->render($r, $params{template}, \%params);
}

__PACKAGE__->meta->make_immutable;
no Moose;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::View::TT - View wrapper class for TT renderers

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package MyApp;
  use OX;

  has 'template_params' => (
      block => sub {
          my $s = shift;
          return {
              some_scalar => 'value',
              some_array => ['one', 'two'],
          };
      },
  );

  has view => (
      is           => 'ro',
      isa          => 'OX::View::TT',
      dependencies => ['template_root', 'template_params'],
  );

=head1 DESCRIPTION

This is a very thin wrapper around L<Template> which exposes some OX
functionality to your template files. It can be passed a template_params
dependency, containing variables that will be passed to the template. Templates
rendered with this class will have access to these additional variables:

=over 4

=item C<base>

The base URL that this app is hosted at (C<SCRIPT_NAME>).

=item C<uri_for>

A function which forwards its arguments to the C<uri_for> method in
L<OX::Request>.

=item C<m>

The hashref of match variables for the current route (equivalent to the
C<mapping> method on the L<OX::Request> object).

=back

=head1 METHODS

=head2 C<< render($r, $template, $params) >>

Renders a template, and returns a string containing the contents. C<$r> is the
request object, C<$template> is the name of the template, and C<$params> are
extra variables to pass to the template.

=head2 C<< template($r) >>

This is an action method which can be used directly as a route endpoint:

  route '/about' => 'view.template', (
      template => 'about.tt',
  );

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/ox-view-tt/issues>.

=head1 SEE ALSO

L<OX>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc OX::View::TT

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/OX-View-TT>

=item * Github

L<https://github.com/doy/ox-view-tt>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OX-View-TT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OX-View-TT>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
