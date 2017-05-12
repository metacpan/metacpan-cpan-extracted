package Sledge::Template::TT::I18N;
use strict;
use base qw(Sledge::Template::TT);

use vars qw($VERSION);
$VERSION = '0.01';

sub output {
    my $self = shift;
    my %config = %{$self->{_options}};
    my $input  = delete $config{filename};
    $config{LOAD_TEMPLATES} = [Sledge::Template::TT::I18N::Provider->new(\%config)];
    my $template = Template->new(\%config);
    unless (-e $input) {
    Sledge::Exception::TemplateNotFound->throw(
        "No template file detected. Check your template path.",
    );
    }
    $template->process($input, $self->{_params}, \my $output)
    or Sledge::Exception::TemplateParseError->throw($template->error);
    return $output;
}

package Sledge::Template::TT::I18N::Provider;
use strict;
use base qw(Template::Provider);

sub _load {
    my $self = shift;

    my ($data, $error) = $self->SUPER::_load(@_);

    if(defined $data) {
        $data->{text} = utf8_upgrade($data->{text});
    }

    return ($data, $error);
}

sub utf8_upgrade {
    my @list = map pack('U*', unpack 'U0U*', $_), @_;
    return wantarray ? @list : $list[0];
}

1;
__END__

=head1 NAME

Sledge::Template::TT::I18N -  Internationalization extension to Sledge::Template::TT.

=head1 SYNOPSIS

  package YourProj::Pages;
  use strict;
  use base qw(Sledge::Pages::Apache::I18N);
  use Sledge::Template::TT::I18N;
  use Sledge::Charset::UTF8::I18N;

  ....

  sub create_charset {
      my $self = shift;
      Sledge::Charset::UTF8::I18N->new($self);
  }

=head1 DESCRIPTION

Sledge::Template::TT::I18N is Internationalization extension to Sledge::Template::TT.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=head1 SEE ALSO

L<Sledge::Template::TT>

=cut
