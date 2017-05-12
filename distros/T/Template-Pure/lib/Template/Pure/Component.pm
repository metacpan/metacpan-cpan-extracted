package Template::Pure::Component;

use Template::Pure;
use Digest::MD5 ();

use base 'Template::Pure';

sub node { shift->{node} }
sub inner {
  my $self = shift;
  return $self->encoded_string(
    $self->{node}->content);
}

sub container { $_[0]->{container} }
sub parent { shift->{parent} }
sub children { @{shift->{children}} }
sub add_child {
  my ($self, $child) = @_;
  push @{shift->{children}}, $child;
  return $self->children;
}

sub style { shift->{style} }
sub style_fragment {
  my $style = $_[0]->style || return;
  my $checksum = Digest::MD5::md5_hex($style);
  return $checksum, "<style type='text/css' id='$checksum'>$style</style>";
}

sub script { shift->{script} }
sub script_fragment {
  my $script = $_[0]->script || return;
  my $checksum = Digest::MD5::md5_hex($script);
  return $checksum, "<script type='text/javascript' id='$checksum'>$script</script>";
}

sub process_root {
  my ($self, $root) = @_;
  if(my($md5, $style) = $self->style_fragment) {
   unless($root->at("style#$md5")) {
      $root->at('head')->append_content("$style\n");
     }  
  }
  if(my($md5, $script) = $self->script_fragment) {
   unless($root->at("script#$md5")) {
      $root->at('head')->append_content("$script\n");
     }  
  }
}

sub prepare_render_callback {
  my $self = shift;
  return sub {
    my ($t, $dom, $data) = @_;
    $self->process_root($dom->root, $data);
    $t->encoded_string($self->render({data=>$data}));
  };
}

1;

=head1 NAME

Template::Pure::Components - Reusable HTML components

=head1 SYNOPSIS

    package Local::Timestamp;

    use Moo;
    use DateTime;

    extends 'Template::Pure::Component';

    has 'tz' => (is=>'ro', predicate=>'has_tz');

    sub style {q[
      .timestamp {
        color: blue;
      }
    ]}

    sub script {q[
      function hello() {
        alert('Hi');
      } 
    ]}

    sub template {
      q[<span class='timestamp' onclick="hello()">time</span>];
    }

    sub directives {
      '.timestamp' => 'self.time',
    }

    sub time {
      my ($self) = @_;
      my $now = DateTime->now;
      $now->set_time_zone($self->tz)
        if $self->has_tz;
      return $now;
    }

=head1 DESCRIPTION

Work in progress.  Play here only if you are willing to get you hands
dirty and have stuff break.

=head1 SEE ALSO
 
L<Template::Pure>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>

But lots of this code was copied from L<Template::Filters> and other prior art on CPAN.  Thanks!
  
=head1 COPYRIGHT & LICENSE
 
Please see L<Template::Pure> for copyright and license information.

=cut 
