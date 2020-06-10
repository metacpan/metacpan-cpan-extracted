package Builder;
use File::Spec;
use File::Find;
use Try::Tiny;
use Config;
use v5.10;
use Cwd;
use base 'Module::Build';
use strict;
use warnings;
__PACKAGE__->add_property( 'inline_modules' );

my $have_p2m = eval "require Pod::Markdown; 1";
# These are kludges to get Inline to create Inline modules that
# * have dependencies on one another
# * Module::Build can test and install properly
# * have runtime config dependencies (user-provided libneo4j-client build
# *  location)

# use Inline compile/install
sub ACTION_build {
  my $self = shift;
  my $mod_ver = $self->dist_version;
  $self->SUPER::ACTION_build;
  for my $m (@{$self->inline_modules}) {
    # this is an undocumented function (_INSTALL_) of Inline
    # that will likely not change, since it is integral to
    # Inline::MakeMaker
    my @cmpts = split(/::/,$m);
    my $fn = "$cmpts[-1].$Config{dlext}";
    print STDERR "Checking for ". File::Spec->catfile($self->blib,qw/arch auto/,@cmpts,$fn)."\n";
    if ( ! -e File::Spec->catfile($self->blib,qw/arch auto/,@cmpts,$fn) ) {
      $self->do_system( $^X, '-Mblib', '-MInline=NOISY,_INSTALL_',
			"-MInline=Config,name,$m,version,$mod_ver",
			"-M$m", "-e", "1", $mod_ver, 'blib/arch');
    }
    else {
      print STDERR "Found ". File::Spec->catfile($self->blib,qw/arch auto/,@cmpts,$fn)."\n";      
    }
  }
}

sub ACTION_install {
  my $self = shift;
  $self->depends_on('build');
  # clear out build utilites - Inline C patch
  print STDERR "Removing cargo cult Inline\n";
  unlink 'blib/lib/Inline/P.pm';
  unlink 'blib/lib/Inline/denter.pm';
  unlink 'blib/lib/Inline/MakeMaker.pm';  
  unlink 'blib/lib/Inline';
  unlink 'blib/lib/Inline.pm';
  $self->SUPER::ACTION_install;
}
 sub ACTION_test {
   my $self = shift;
   unless (-d File::Spec->catdir(qw/blib arch auto Neo4j Bolt/)) {
     $self->depends_on('build');
   }
   $self->SUPER::ACTION_test;
 }

 sub ACTION_author_tasks {
   my $self = shift;
   my ($action, $subaction) = @ARGV;
   if ($subaction && ($subaction eq 'readme')) {
     unless ($have_p2m) {
       print "Don't have Pod::Markdown\n";
       return;
     }
     # write POD as <Module>.md in relevant lib/ subdirs
     find (
       sub {
	 return unless $_ =~ /^(.*)\.pm$/;
	 my ($name) = $1;
	 die unless defined $name;
	 my $mdstr = '';
	 my $p2m = Pod::Markdown->new();
	 $p2m->local_module_url_prefix('github::');
	 $p2m->local_module_re(qr/^Neo4j::/);
	 $p2m->output_string(\$mdstr);
	 $p2m->parse_file($_);
 	 $mdstr =~ s/%3A%3A/::/g;
	 $mdstr =~ s{(\][(]github::[^)]*[)])}
		    {
		      $_ = $1;
		      s|github::|/lib/|;
		      s|::|/|g;
		      s|[)]$|.md)|;
		      $_
		    }eg;
	 if (length $mdstr > 1) {
	   open my $mdf, '>', "$name.md" or die $!;
	   print $mdf $mdstr;
	   close $mdf;
	 }
       },
       File::Spec->catdir($self->base_dir,'lib')
      );
     
   }
   else {
     print STDERR "Valid author tasks are:\n\treadme\n";
     exit 1;
   }
   # use the dist-version-from .pm's .md as README.md
   if ($self->dist_version_from) {
     my $mdf = $self->dist_version_from;
     $mdf =~ s/\.pm/\.md/;
     $self->copy_if_modified( from => $mdf, to => 'README.md' );
   }
 }

1;
