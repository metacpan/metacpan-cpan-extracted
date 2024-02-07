package Selenium::Client::Commands;
$Selenium::Client::Commands::VERSION = '2.00';
# ABSTRACT: Map commands from Selenium 3 to 4

use strict;
use warnings;

use Carp::Always;

# Polyfill from Selenium 4's spec to JSONWire + Selenium 3
my %using = (
    'class name' => sub { ( "css selector", ".$_[0]" ) },
    'name'       => sub { ( "css selector", "[name='$_[0]']" ) },
    'id'         => sub { ( "css selector", "#$_[0]" ) },
);

sub _toughshit {
    my ( $session, $params, $cmd ) = @_;
    die "Sorry, Selenium 4 does not support $cmd!  Try downgrading your browser, driver binary, Selenium JAR and so forth to something that understands JSONWire protocol, Selenium 3, or use playwright which supports all this functionality and more.";
}

sub _emit {
    my ( $session, $ret ) = @_;
    return $ret;
}

sub _emit_null_ok {
    my ( $session, $ret ) = @_;
    return !defined $ret;
}

sub _timeout {
    my ( $session, $params ) = @_;
    return $session->SetTimeouts(%$params);
}

sub _sess_uc {
    my ( $session, $params, $cmd ) = @_;
    $cmd = ucfirst($cmd);
    die "NO SESSION PROVIDED!" unless $session;
    return $session->$cmd(%$params);
}

my %command_map = (
    'status' => {
        driver  => 1,
        execute => sub {
            my ( $driver, $params ) = @_;
            return $driver->Status();
        },
        parse => sub {
            my ( $driver, $ret ) = @_;
            return $ret;
        },
    },
    'newSession' => {
        driver  => 1,
        execute => sub {
            my ( $driver, $params ) = @_;
            foreach my $key ( keys(%$params) ) {

                #XXX may not be the smartest idea
                delete $params->{$key} unless $params->{$key};
            }

            my %in  = %$params ? ( capabilities => { alwaysMatch => $params } ) : ();
            my @ret = $driver->NewSession(%in);
            return [@ret];
        },
        parse => sub {
            my ( $driver,       $ret )     = @_;
            my ( $capabilities, $session ) = @$ret;
            return { capabilities => $capabilities, session => $session };
        },
    },
    'setTimeout' => {
        execute => \&_timeout,
        parse   => \&_emit,
    },
    'setAsyncScriptTimeout' => {
        execute => \&_timeout,
        parse   => \&_emit,
    },
    'setImplicitWaitTimeout' => {
        execute => \&_timeout,
        parse   => \&_emit,
    },
    'getTimeouts' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetTimeouts();
        },
        parse => \&_emit,
    },

    #TODO murder the driver object too
    'quit' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->DeleteSession( sessionid => $session->{sessionid} );
        },
        parse => \&_emit_null_ok,
    },
    'getCurrentWindowHandle' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetWindowHandle(%$params);
        },
        parse => \&_emit,
    },
    'getWindowHandles' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },

    #TODO May require output filtering
    'getWindowSize' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetWindowRect(%$params);
        },
        parse => \&_emit,
    },
    'getWindowPosition' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetWindowRect(%$params);
        },
        parse => \&_emit,
    },
    'getWindowRect' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'setWindowRect' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'maximizeWindow' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'maximizeWindow' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'minimizeWindow' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'fullscreenWindow' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'setWindowSize' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->SetWindowRect(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'setWindowPosition' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->SetWindowRect(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'getCurrentUrl' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetCurrentURL(%$params);
        },
        parse => \&_emit,
    },
    'get' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->NavigateTo(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'goForward' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->Forward(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'goBack' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->Back(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'refresh' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'executeScript' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'executeAsyncScript' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'screenshot' => {
        execute => sub {
            my ( $session, $params ) = @_;
            $session->TakeScreenshot(%$params);
        },
        parse => \&_emit,
    },
    'elementScreenshot' => {
        session => 1,
        execute => sub {
            my ( $session, $params ) = @_;
            $session->TakeElementScreenshot(%$params);
        },
        parse => \&_emit,
    },
    'availableEngines' => {
        execute => \&_toughshit,
    },
    'switchToFrame' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'switchToParentFrame' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'switchToWindow' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'getAllCookies' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getCookieNamed' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->GetNamedCookie(%$params);
        },
        parse => \&_emit,
    },
    'addCookie' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'deleteAllCookies' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'deleteCookieNamed' => {
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->DeleteCookie(%$params);
        },
        parse => \&_emit,
    },
    'getPageSource' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getTitle' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'findElement' => {
        scd     => 1,
        execute => sub {
            my ( $driver, $params ) = @_;

            # Fix old selector types
            ( $params->{using}, $params->{value} ) = $using{ $params->{using} }->( $params->{value} ) if exists $using{ $params->{using} };
            my $element = $driver->session->FindElement(%$params);
            return $element;
        },
        parse => \&_emit,
    },
    'findElements' => {
        scd     => 1,
        execute => sub {
            my ( $driver, $params ) = @_;

            # Fix old selector types
            ( $params->{using}, $params->{value} ) = $using{ $params->{using} }->( $params->{value} ) if exists $using{ $params->{using} };
            my @elements = $driver->session->FindElements(%$params);
            return wantarray ? @elements : \@elements;
        },
        parse => \&_emit,
    },
    'getActiveElement' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'describeElement' => {
        execute => \&_toughshit,
    },
    'findChildElement' => {
        execute => \&_toughshit,
    },
    'findChildElements' => {
        execute => \&_toughshit,
    },
    'clickElement' => {
        execute => sub {
            my ( $element, $params ) = @_;
            $element->ElementClick(%$params);
        },
        parse => \&_emit_null_ok,
    },

    # TODO polyfill as send enter?
    'submitElement' => {
        execute => \&_toughshit,
    },
    'sendKeysToElement' => {
        execute => sub {
            my ( $element, $params ) = @_;
            $element->ElementSendKeys(%$params);
        },
        parse => \&_emit,
    },
    'sendKeysToActiveElement' => {
        execute => \&_toughshit,
    },
    'sendModifier' => {
        execute => \&_toughshit,
    },
    'isElementSelected' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },

    # TODO polyfill
    'setElementSelected' => {
        execute => \&_toughshit,
    },
    'toggleElement' => {
        execute => \&_toughshit,
    },
    'isElementEnabled' => {
        element => 1,
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getElementLocation' => {
        execute => sub {
            my ( $element, $params ) = @_;
            return $element->GetElementRect(%$params);
        },
        parse => \&_emit,
    },
    'getElementRect' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getElementLocationInView' => {
        execute => \&_toughshit,
    },
    'getElementTagName' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'clearElement' => {
        execute => sub {
            my ( $element, $params ) = @_;
            return $element->ElementClear(%$params);
        },
        parse => \&_emit,
    },
    'getElementAttribute' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getElementProperty' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },

    # TODO polyfills
    'elementEquals' => {
        execute => \&_toughshit,
    },
    'isElementDisplayed' => {
        execute => \&_toughshit,
    },
    'close' => {
        execute => sub {
            my ( $session, $params ) = @_;
            $session->closeWindow(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'getElementSize' => {
        execute => sub {
            my ( $element, $params ) = @_;
            return $element->GetElementRect(%$params);
        },
        parse => \&_emit,
    },
    'getElementText' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'getElementValueOfCssProperty' => {
        execute => sub {
            my ( $element, $params ) = @_;
            return $element->GetElementCSSValue(%$params);
        },
        parse => \&_emit,
    },
    'mouseMoveToLocation' => {
        execute => \&_toughshit,
    },
    'getAlertText' => {
        execute => \&_sess_uc,
        parse   => \&_emit,
    },
    'sendKeysToPrompt' => {
        execute => sub {
            my ( $session, $params ) = @_;
            $session->SendAlertText(%$params);
        },
        parse => \&_emit_null_ok,
    },
    'acceptAlert' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'dismissAlert' => {
        execute => \&_sess_uc,
        parse   => \&_emit_null_ok,
    },
    'click' => {
        execute => \&_toughshit,
    },
    'doubleClick' => {
        execute => \&_toughshit,
    },
    'buttonDown' => {
        execute => \&_toughshit,
    },
    'buttonUp' => {
        execute => \&_toughshit,
    },
    'uploadFile' => {
        execute => \&_toughshit,
    },
    'getLocalStorageItem' => {
        execute => \&_toughshit,
    },
    'deleteLocalStorageItem' => {
        execute => \&_toughshit,
    },
    'cacheStatus' => {
        execute => \&_toughshit,
    },
    'setGeolocation' => {
        execute => \&_toughshit,
    },
    'getGeolocation' => {
        execute => \&_toughshit,
    },
    'getLog' => {
        execute => \&_toughshit,
    },
    'getLogTypes' => {
        execute => \&_toughshit,
    },
    'setOrientation' => {
        execute => \&_toughshit,
    },
    'getOrientation' => {
        execute => \&_toughshit,
    },

    # firefox extension
    'setContext' => {
        execute => \&_toughshit,
    },
    'getContext' => {
        execute => \&_toughshit,
    },

    # geckodriver workarounds
    'executeScriptGecko' => {
        execute => \&_toughshit,
    },
    'executeAsyncScriptGecko' => {
        execute => \&_toughshit,
    },
    generalAction => {
        session => 1,
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->PerformActions(%$params);
        },
        parse => \&_emit_null_ok,
    },
    releaseGeneralAction => {
        session => 1,
        execute => sub {
            my ( $session, $params ) = @_;
            return $session->ReleaseActions(%$params);
        },
        parse => \&_emit_null_ok,
    },
);

sub new {
    my $class = shift;
    return bless( {}, $class );
}

# Act like S::R::C
sub parse_response {
    my ( $self, $driver, $command, $response ) = @_;
    return $command_map{$command}{parse}->( $driver, $response );
}

# Act like S::R::RR
sub request {
    my ( $self, $driver, $command, $args ) = @_;
    die "No such command $command" unless ref $command_map{$command} eq 'HASH';
    return $command_map{$command}{execute}->( $driver, $args, $command );
}

sub needs_driver {
    my ( $self, $command ) = @_;
    return $command_map{$command}{driver};
}

sub needs_scd {
    my ( $self, $command ) = @_;
    return $command_map{$command}{scd};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Client::Commands - Map commands from Selenium 3 to 4

=head1 VERSION

version 2.00

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
