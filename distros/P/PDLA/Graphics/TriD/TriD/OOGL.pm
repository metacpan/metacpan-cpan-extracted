package PDLA::Graphics::TriD::OOGL;

$PDLA::Graphics::TriD::create_window_sub = sub {
   return new PDLA::Graphics::TriD::OOGL::Window;
};


package PDLA::Graphics::TriD::Object;

#use PDLA::Graphics::OpenGL;

BEGIN {
   use PDLA::Config;
   if ($PDLA::Config{USE_POGL}) {
      eval "use OpenGL $PDLA::Config{POGL_VERSION} qw(:all)";
   }
}

use PDLA::Graphics::OpenGL::Perl::OpenGL;
sub tooogl {
   my($this) = @_;
   join "\n",map { $_->togl() } (@{$this->{Objects}})
}

package PDLA::Graphics::TriD::GL::Window;
use FileHandle;

sub new {my($type) = @_;
   my($this) = bless {},$type;
}

sub update_list {

   local $SIG{PIPE}= sub {}; # Prevent crashing if user exits the pager

   my($this) = @_;
   my $fh = new FileHandle("|togeomview");
   my $str = join "\n",map {$_->tooogl()} (@{$this->{Objects}}) ;
   print $str;
   $fh->print($str);
}

sub twiddle {
}
