#line 1
package UNIVERSAL::require;
$UNIVERSAL::require::VERSION = '0.11';

# We do this because UNIVERSAL.pm uses CORE::require().  We're going
# to put our own require() into UNIVERSAL and that makes an ambiguity.
# So we load it up beforehand to avoid that.
BEGIN { require UNIVERSAL }

package UNIVERSAL;

use strict;

use vars qw($Level);
$Level = 0;

#line 69

sub require {
    my($module, $want_version) = @_;

    $UNIVERSAL::require::ERROR = '';

    die("UNIVERSAL::require() can only be run as a class method")
      if ref $module; 

    die("UNIVERSAL::require() takes no or one arguments") if @_ > 2;

    my($call_package, $call_file, $call_line) = caller($Level);

    # Load the module.
    my $file = $module . '.pm';
    $file =~ s{::}{/}g;

    # For performance reasons, check if its already been loaded.  This makes
    # things about 4 times faster.
    return 1 if $INC{$file};

    my $return = eval qq{ 
#line $call_line "$call_file"
CORE::require(\$file); 
};

    # Check for module load failure.
    if( $@ ) {
        $UNIVERSAL::require::ERROR = $@;
        return $return;
    }

    # Module version check.
    if( @_ == 2 ) {
        eval qq{
#line $call_line "$call_file"
\$module->VERSION($want_version);
};

        if( $@ ) {
            $UNIVERSAL::require::ERROR = $@;
            return 0;
        }
    }

    return $return;
}


#line 136

sub use {
    my($module, @imports) = @_;

    local $Level = 1;
    my $return = $module->require or return 0;

    my($call_package, $call_file, $call_line) = caller;

    eval qq{
package $call_package;
#line $call_line "$call_file"
\$module->import(\@imports);
};

    if( $@ ) {
        $UNIVERSAL::require::ERROR = $@;
        return 0;
    }

    return $return;
}


#line 191


1;
