package Net::Amazon::MechanicalTurk::Command::SetQuestionPostValidationOnError;
use strict;
use warnings;
use Net::Amazon::MechanicalTurk::QAPValidator;
use Carp;

our $VERSION = '1.00';

#
# Extension method which hooks the CreateHIT api call
# in order to validate the QAP on XML error and try to give
# a better error message.
#
# Note: There is a CPAN module called XML::Validate
#   (It didn't find and download the schema on MSXML though for some reason).
#
# This code is experimental and currently only works on Windows.
#

sub setQuestionPostValidationOnError {
    my ($mturk, $value) = @_;
    
    if ($value) {
        createValidator(); # Make sure there is a validator
        if (!$mturk->filterChain->hasFilter(\&validator)) {
            $mturk->filterChain->addFilter(\&validator);
        }
    }
    else {
        $mturk->filterChain->removeFilter(\&validator);
    }
}

sub createValidator {
    return Net::Amazon::MechanicalTurk::QAPValidator->create;
}

sub validator {
    my ($chain, $targetParams) = @_;
    my ($mturk, $operation, $params) = @$targetParams;
    
    if ($operation ne "CreateHIT") {
        return $chain->();
    }
    else {
        my $result;
        eval {
            $result = $chain->();
        };
        if ($@) {
            my $error = $@;
            if (exists $params->{Question} and
                $mturk->response and
                $mturk->response->errorCode and
                $mturk->response->errorCode =~ /XMLParseError/)
            {
                my $validated = 1;
                my $info = {};
                eval {
                    $validated = createValidator()->validate($params->{Question}, $info);
                };
                if (!$validated) {
                    Carp::croak(sprintf "%s\n%s\nLocation: line %s column %s.\n\n%s",
                        $error,
                        $info->{message},
                        $info->{line},
                        $info->{column},
                        $params->{Question});
                }
                else {
                    Carp::croak(sprintf "%s\n\n%s",
                        $error,
                        $params->{Question});
                }
            }
            else {
                Carp::croak($error);
            }
        }
        return $result;
    }
}

return 1;
