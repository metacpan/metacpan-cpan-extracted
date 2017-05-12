package TaskForest::REST::Status;

use strict;
use warnings;
use HTTP::Status;
use TaskForest;
use TaskForest::REST;
use Data::Dumper;
use DateTime;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.34';
}

sub handle {
    my ($q, $parent_hash, $h) = @_;
    my $hash = { title => "Status" };

    my $method = $parent_hash->{method};

    my %functions = ( PUT => \&PUT, GET => \&GET, HEAD => \&HEAD, DELETE => \&DELETE, POST => \&POST);
                      
    $functions{$method}->($q, $parent_hash, $h, $hash);

    # TODO: in version 1 . 16 or later
#     my @sorts = ();
#     my $seen = {};
#     if ($h->{sort1} and !$seen->{$h->{sort1}}) { push (@sorts, $h->{sort1});  $seen->{$h->{sort1}} = 1; }
#     if ($h->{sort2} and !$seen->{$h->{sort2}}) { push (@sorts, $h->{sort2});  $seen->{$h->{sort2}} = 1; }
#     if ($h->{sort3} and !$seen->{$h->{sort3}}) { push (@sorts, $h->{sort3});  $seen->{$h->{sort3}} = 1; }
#     if ($h->{sort4} and !$seen->{$h->{sort4}}) { push (@sorts, $h->{sort4});  $seen->{$h->{sort4}} = 1; }

#     if (@sorts) {
#     }

    
    return $hash;
}

sub PUT     { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub HEAD    { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub DELETE  { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }
sub POST    { &TaskForest::REST::methodNotAllowed($_[1], 'GET'); }

sub GET {
    my ($q, $parent_hash, $h, $hash) = @_;

    $ENV{TF_RUN_WRAPPER}       = "UNNECESSARY";
    $ENV{TF_LOG_DIR}           = $parent_hash->{config}->{log_dir};
    $ENV{TF_JOB_DIR}           = $parent_hash->{config}->{job_dir};
    $ENV{TF_FAMILY_DIR}        = $parent_hash->{config}->{family_dir};
    $ENV{TF_CALENDAR_DIR}      = $parent_hash->{config}->{calendar_dir};
    $ENV{TF_CHAINED}           = $parent_hash->{config}->{chained};
    $ENV{TF_DEFAULT_TIME_ZONE} = $parent_hash->{config}->{default_time_zone};

    
    my $task_forest  = TaskForest->new();
    my $data_only = 1;
    my $display_hash;

    if ($h->{date}) {
        $h->{date} =~ /(\d{8})/;
        $h->{date} = $1;
        
        $display_hash = $task_forest->hist_status($h->{date}, $data_only);
        $hash->{date} = $h->{date};
        $hash->{title} = "Logs for $hash->{date}";
        my ($y, $m, $d) = $h->{date} =~ /(\d{4})(\d{2})(\d{2})/;
        my $dt = DateTime->new(year => $y,
                               month => $m,
                               day => $d,
                               hour => 0,
                               minute => 0,
                               second => 0,
            );
        
        $hash->{prev_date} = $dt->subtract(days => 1)->ymd('');
        $hash->{next_date} = $dt->add(days => 2)->ymd('');
    }
    else {
        $display_hash = $task_forest->status($data_only);
        $hash->{title} = "Status";
    }

    my @final_display = grep { ! ($_->{name} =~ /\-\-Repeat/ and $_->{status} eq 'Waiting') } @{$display_hash->{all_jobs}};

    $hash->{status} = \@final_display;

}

1;
