package Module::ConfigureRequires;
$VERSION = '0.03';

sub inc::Module::ConfigureRequires::import {
 $recursive = $ARGV[0] eq 'mcrrecursive' ? shift @ARGV : 0;
}

sub import {
 local $^W;
 return unless $_[1] eq 'bundle-up';

 require File'Path;
 require File'Spec'Functions;
 require File'Copy;
 File'Path'mkpath(File'Spec'Functions'catfile(qw<inc Module>));
 my $from = __FILE__;
 my $to = File'Spec'Functions'catfile(qw<inc Module ConfigureRequires.pm>);
 File'Copy'copy($from, $to)
  or die "Cannot copy $from to $to: $!";

 require ExtUtils'Manifest;
 ExtUtils'Manifest'maniadd({'inc/Module/ConfigureRequires.pm'=>undef});

 exit 0;
}

sub set_up {
 for($0, (caller)[1]) {
  /\bMakefile\.PL\z/i and goto &set_up_for_mm;
  /\bBuild\.PL\z/i and goto &set_up_for_mb;
 }
 require Carp;
 Carp'croak(
     __PACKAGE__." cannot determine whether you are using Module::Build"
                ." or ExtUtils::MakeMaker. Please call set_up_for_mm or"
                ." set_up_for_mb directly."
 );
}

sub set_up_for_mm {
  my (%args) = @_;
  !defined $recursive and inc::Module::ConfigureRequires::import();
  if($recursive) { require Carp; Carp'croak($args{error_message} || <<"") }
Please install all the modules that this software requires, and then
re-run $0.

  package
   MY;
  *top_targets = sub {
    my $inherited = SUPER'top_targets{shift}@'_;
    my $mpl_args = join " ", map qq["$_"], @ARGV;
    $inherited
     =~ s<^(all\s*::)(.*?(\r?\n))><
           "newmakefilepl ::$3"
          ."\t\$(PERLRUN) Makefile.PL mcrrecursive $mpl_args$3"
          ."\t\$(MAKE) \$(PASTHRU)$3$3"
          ."$1 newmakefilepl$2"
         >me;
    $inherited;
  };
 _:
}

sub set_up_for_mb {
  my (%args) = @_;
  !defined $recursive and inc::Module::ConfigureRequires::import();
  if($recursive) { require Carp; Carp'croak($args{error_message} || <<"") }
Please install all the modules that this software requires, and then
re-run $0.

  require Module::Build::Base; # in case it’s not already loaded
  my $orig = \&Module::Build::Base::create_build_script;
  local $^W;
  *Module::Build::Base::create_build_script = sub {
    my($self) = @_;
    &$orig;
    open fH, ">" . $self->build_script;
    my $shebang = $self->config('startperl');
    my @args = map {; s/([\\'])/\\$1/g; "'$_'" } $0, @ARGV;
    my $args = join ",", $args[0], 'mcrrecursive', @args[1..$#args];
    print fH <<"";
$shebang
use Module'Build;
my \$perl = Module'Build->find_perl_interpreter;
system \$perl, $args, == 0 and system \$perl, __FILE__, \@ARGV;

    close fH or die "Error printing to " . $self->build_script . ": $!";
    return 1;
  };
 _:
}

(undef) = (undef);
