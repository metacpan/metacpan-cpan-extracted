use Test::More tests => 2;
use Config;

my $RUNNING_IN_HELL = $^O eq 'MSWin32' ? 1 : 0;

use_ok("POE::Component::SmokeBox");

my $ok;

diag("\n\nTesting POE::Component::SmokeBox-" . POE::Component::SmokeBox->VERSION() . "\n\n");

diag("\n\nCode borrowed from XML::Twig by MIROD\n");
diag("\nConfiguration:\n\n");

# required
diag("perl: $]\n");
diag("OS: $Config{'osname'} - $Config{'myarchname'}\n");

diag("\n");

diag( version( 'POE', 'required' ) );
diag( version( 'Module::Pluggable', 'required' ) );
diag( version( 'Object::Accessor', 'required' ) );
diag( version( 'Params::Check', 'required' ) );
diag( version( 'Digest::MD5', 'required' ) );
diag( version( 'IO::Pty', 'strongly recommended' ) ) unless $RUNNING_IN_HELL;
diag( version( 'POE::Wheel::Run::Win32', 'required' ) ) if $RUNNING_IN_HELL;

diag "\n";

diag( version( 'Test::More', 'required for build' ) );
diag( version( 'File::Spec', 'required for build' ) );

diag("\n");

sleep 1;

pass("Everything is cool");

exit 0;

sub version
  { my $module= shift;
    my $info= shift || '';
    $info &&= "($info)";
    my $version;
    if( eval "require $module")
      { $ok=1;
        import $module;
        $version= ${"$module\::VERSION"};
        $version=~ s{\s*$}{};
      }
    else
      { $ok=0;
        $version= '<not available>';
      }
    return format_warn( $module, $version, $info);
  }

sub format_warn
  { return  sprintf( "%-25s: %16s %s\n", @_); }

