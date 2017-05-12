package TaskForest::REST::Request;

use strict;
use warnings;
use HTTP::Status;
use TaskForest::REST;
use TaskForest::LogDir;
use TaskForest::Rerun;
use TaskForest::Mark;
use TaskForest::Hold;
use TaskForest::Release;
use Data::Dumper;

sub handle {
    my ($q, $parent_hash, $h) = @_;
    my $hash = { title => "Request" };

    my $method = $parent_hash->{method};

    my %functions = ( PUT => \&PUT, GET => \&GET, HEAD => \&HEAD, DELETE => \&DELETE, POST => \&POST);
                      
    $functions{$method}->($q, $parent_hash, $h, $hash);

    return $hash;
}

sub PUT     { &TaskForest::REST::methodNotAllowed($_[1], 'POST'); }
sub HEAD    { &TaskForest::REST::methodNotAllowed($_[1], 'POST'); }
sub DELETE  { &TaskForest::REST::methodNotAllowed($_[1], 'POST'); }
sub GET     { &TaskForest::REST::methodNotAllowed($_[1], 'POST'); }

sub POST {
    my ($q, $parent_hash, $h, $hash) = @_;

    my $family_name     = $h->{family};
    my $job_name        = $h->{job};
    my $job_dir         = $parent_hash->{config}->{job_dir};
    my $family_dir      = $parent_hash->{config}->{family_dir};
    my $log_dir         = &TaskForest::LogDir::getLogDir($parent_hash->{config}->{log_dir});
    my $request         = $h->{submit};
    my $cascade         = ($h->{options} && ($h->{options} eq 'cascade'))         ? 1 : undef;
    my $dependents_only = ($h->{options} && ($h->{options} eq 'dependents_only')) ? 1 : undef;

    if ($h->{log_date}) {
        my $log_date = $h->{log_date};
        $log_date    =~ /(\d+)/;
        $log_date    = $1;
        $log_dir     = $parent_hash->{config}->{log_dir}."/$log_date";
    }
    
    $family_name        =~ /([a-z0-9_]+)/i; $family_name = $1;
    $job_name           =~ /([a-z0-9_\-]+)/i; $job_name    = $1;
    my $quiet = 1;
    my $error = "";

    if ($request =~ /^Mark/) {
        my $status = $h->{status};
        if (!$status) {
            $request =~ /Mark (\S+)/;
            $status = $1;
        }
        eval { 
            &TaskForest::Mark::mark($family_name, $job_name, $log_dir, $status, $cascade, $dependents_only, $family_dir, $quiet);
        };
        $error = $@;
        if ($error) {
            $hash->{message}            = "Error.  Either the job hasn't run yet or is already marked ".
                                          "as requested.  The system returned the following error:";
            $hash->{error}              = $error;
            $hash->{error}              =~ s/</&lt;/g;
            $hash->{error}              =~ s/>/&gt;/g;
            $parent_hash->{http_status} = RC_INTERNAL_SERVER_ERROR;
        }
    }
    elsif ($request eq "Rerun") {
        eval { 
            &TaskForest::Rerun::rerun($family_name, $job_name, $log_dir, $cascade, $dependents_only, $family_dir, $quiet);
        };
        $error = $@;
        if ($error) {
            $hash->{message}            = "Error.  Either the job hasn't run yet or some of the ".
                                          "supporting files are missing.  The system returned the following error:";
            $hash->{error}              = $error;
            $hash->{error}              =~ s/</&lt;/g;
            $hash->{error}              =~ s/>/&gt;/g;
            $parent_hash->{http_status} = RC_INTERNAL_SERVER_ERROR;
        }
    }
    elsif ($request eq "Release") {
        eval { 
            &TaskForest::Release::release($family_name, $job_name, $log_dir, $family_dir, $quiet);
        };
        $error = $@;
        if ($error) {
            $hash->{message}            = "Unknown Error.  Please contact the TaskForest discussion mailing list.";
            $hash->{error}              = $error;
            $hash->{error}              =~ s/</&lt;/g;
            $hash->{error}              =~ s/>/&gt;/g;
            $parent_hash->{http_status} = RC_INTERNAL_SERVER_ERROR;
        }
    }
    elsif ($request eq "Hold") {
        eval { 
            &TaskForest::Hold::hold($family_name, $job_name, $log_dir, $family_dir, $quiet);
        };
        $error = $@;
        if ($error) {
            $hash->{message}            = "Unknown Error.  Please contact the TaskForest discussion mailing list.";
            $hash->{error}              = $error;
            $hash->{error}              =~ s/</&lt;/g;
            $hash->{error}              =~ s/>/&gt;/g;
            $parent_hash->{http_status} = RC_INTERNAL_SERVER_ERROR;
        }
    }
    elsif ($request eq "Release Hold") {
        eval { 
            &TaskForest::Hold::releaseHold($family_name, $job_name, $log_dir, $family_dir, $quiet);
        };
        $error = $@;
        if ($error) {
            $hash->{message}            = "Unknown Error.  Please contact the TaskForest discussion mailing list.";
            $hash->{error}              = $error;
            $hash->{error}              =~ s/</&lt;/g;
            $hash->{error}              =~ s/>/&gt;/g;
            $parent_hash->{http_status} = RC_INTERNAL_SERVER_ERROR;
        }
    }
    else {
        $parent_hash->{http_status} = RC_BAD_REQUEST;
        $parent_hash->{http_content} = "500 - Bad Request.  The only supported TaskForest requests are Mark, Rerun, Release, Hold and 'Release Hold'.";
    }

    
    $hash->{ok} = 1;

}

1;
