package Template::Lace::Utils;

use Exporter 'import';
use Template::Lace::ComponentCallback;

our @EXPORT_OK = (qw/mk_component/);
our %EXPORT_TAGS = (All => \@EXPORT_OK, ALL => \@EXPORT_OK);

sub mk_component(&) { return Template::Lace::ComponentCallback->new(@_) }

1;

=head1 NAME

Template::Lace::Utils - Utility Methods

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

A collection of helpful utility methods

=head1 mk_component

Make a callback component.  See L<Template::Lace::ComponentCallback>.  Example:

    use Template::Lace::Utils 'mk_component';
    my $factory = Template::Lace::Factory->new(
      model_class=>'Local::Template::User',
      component_handlers=>+{
        tag => {
          anchor => mk_component {
            my ($self, %attrs) = @_;
            return "<a href='$_{href}' target='$_{target}'>$_{content}</a>";
          },
        },
      },
    );


=head1 SEE ALSO
 
L<Template::Lace>.

=head1 AUTHOR

Please See L<Template::Lace> for authorship and contributor information.
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Lace> for copyright and license information.

=cut
