package Builder;
use File::Spec;
use File::Find;
use Try::Tiny;
use base 'Module::Build';
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
  my $libdir = '/usr/local/lib';
  my $liba;
  open my $cf, ">", File::Spec->catfile($self->base_dir,qw/lib Neo4j Bolt Config.pm/) or die $!;
  my $lib = "libneo4j-client.a";
  for my $L (@{$self->extra_linker_flags}) {
    if ($L =~ /^-L([^[:space:]]*)(?:\s+|$)/) {
      my $l = $1;
      $liba = File::Spec->catfile($l, $lib);
      last if -e $liba;
    }
  }
  unless ($liba =~ m|/|) {
    $liba = File::Spec->catfile($libdir, $lib);
  }
  my $extl = join(" ", @{$self->extra_linker_flags});
  my $extc = join(" ", @{$self->extra_compiler_flags});
  print $cf "package Neo4j::Bolt::Config;\n\$extl = '$extl';\n\$extc = '$extc';\n\$liba='$liba';\n1;\n";
  close $cf;
  $self->SUPER::ACTION_build;
  for my $m (@{$self->inline_modules}) {
    # this is an undocumented function (_INSTALL_) of Inline
    # that will likely not change, since it is integral to
    # Inline::MakeMaker
    $self->do_system( $^X, '-Mblib', '-MInline=NOISY,_INSTALL_',
		      "-MInline=Config,name,$m,version,$mod_ver",
		      "-M$m", "-e", "1", $mod_ver, 'blib/arch');
  }


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
