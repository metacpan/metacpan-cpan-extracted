# WIZARD_GROUP PBS
# WIZARD_NAME  prf, PBS response file
# WIZARD_DESCRIPTION example of a perl base prf file
# WIZARD_ON

print <<'EOT' ;

AddCommandLineSwitches
        (
          '-sd .'
        , "-sd $ENV{SOMETHING}"
        , '-nh'
        ) ;

AddCommandLineDefinitions(PERL_TEST_MODULE => 1) ;

AddTargets('all') ;

EOT

1;

