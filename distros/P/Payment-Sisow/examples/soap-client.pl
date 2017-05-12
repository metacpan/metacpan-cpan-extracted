#!/usr/bin/env perl
# Demonstrates/tests the Sisow interface.
# You first need to copy config.init.templ to config.ini and change
# the parameters to fit your setup.
use warnings;
use strict;

use lib 'lib', '../lib';  # find not yet installed module
use lib '../AnyHTTP/lib'; # markov devel path

use Log::Report   'sisow', mode => 'VERBOSE';

use Payment::Sisow::SOAP ();
use Any::Daemon::HTTP    ();
use Config::Tiny         ();
use File::Slurp          qw/read_file/;

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Quotekeys = 0;

sub frontpage($$$$);
sub update_banks($);
sub start_trans($);
sub show_status($);
sub show_info($);
sub notify($);
sub read_banks($);
my @errors;

my $config  = Config::Tiny->read('config.ini')
           || Config::Tiny->read('examples/config.ini')
    or error __x"create a config.ini from config.ini.templ";

#warn Dumper $config;

my $sconfig = $config->{sisow};
my $sisow   = Payment::Sisow::SOAP->new(%$sconfig);
#$sisow->wsdl->printIndex;

my $dconfig = $config->{daemon};
my $hconfig = $config->{http};
my $daemon  = Any::Daemon::HTTP->new(%$dconfig, %$hconfig);

print "Working in ".$daemon->workdir, "\n";
print "Connect your browser to http://$hconfig->{host}\n";
print "Stop with cntrl-C, wait 2 seconds\n";

# When the next two lines are uncommented, all errors and warnings are
# also sent to syslog. Output still also to the screen.
#dispatcher SYSLOG => 'syslog', accept => 'INFO-'
#   , identity => 'payment-soap', facility => 'local0';

# When the next line is uncommented, the errors/warnings will not show
# on stderr anymore.
#dispatcher close => 'default';

$daemon->run
  ( max_childs     => 2  # need at least 2, one for notifications!
  , background     => 0  # cntrl-C will work, wait 2 seconds to terminate
  , handle_request => \&handle_request
  );

sub handle_request($$$)
{   my ($daemon, $client, $req) = @_;
    my $path = $req->uri->path;
    my %qf   = $req->uri->query_form;
    my $test = $qf{testmode} ? 1 : 0;

    #info "PATH=$path";
    update_banks($test) if $qf{update_banks};
    start_trans(\%qf)   if $qf{start_trans};

    ### now implement Plack ;-)

    # Process "delete"
    if($path =~ m!/(delete|status|info)/(\w+)$!)
    {   my ($action, $fn) = ($1, "t_$2");

           if($action eq 'delete') { unlink $fn      }
        elsif($action eq 'status') { show_status $fn }
        elsif($action eq 'info')   { show_info $fn   }
    }

    if($path eq '/notify')
    {   notify \%qf;
    }

    frontpage $client, $req, \%qf, $test;
}

sub frontpage($$$$)
{   my ($client, $req, $qf, $test) = @_;

    my $resp = HTTP::Response->new
      ( 200, 'OK'
      , [ Content_Type => 'text/html' ]
      );
    my $who  = $sisow->merchantId;

my $x = ''; # Dumper $qf; $x.= $resp->as_string;

    my $testmode = $test ? ' CHECKED' : '';
    my $errors   = join "<br>\n", @errors;

    my @banks    = map {$_->[1] .= " (NL, iDEAL)"; $_} read_banks $test;
    push @banks
      , [ sofort     => 'sofort/DIRECTebanking (DE)' ]
      , [ mistercash => 'BanContact/MisterCash (BE)' ]
          unless $test;

    my @banksel = map qq{<option value="$_->[0]">$_->[1]</option>\n}, @banks;

    my @trans   = <<__HEADER;
<tr align="left">
    <th>Txid</th>
    <th>Purchase</th>
    <th>Amount</th>
    <th>Description</th>
    <th>Status</th>
    <th>Actions</th></tr>
__HEADER

    foreach my $trans_fn (glob 't_*')
    {   my $t      = do $trans_fn;
        my $trxid   = $t->{start}{trxid};
        my $notifs = $t->{notifies};
        my $status = @$notifs ? $notifs->[-1]{status} : 'started';

        push @trans, <<__TRANS;
<tr><td>$trxid</td>
    <td>$t->{purchase_id}</td>
    <td>$t->{amount}&euro;</td>
    <td>$t->{description}</td>
    <td>$status</td>
    <td><a href="/delete/$trxid?testmode=$test">delete</a>,
        <a href="$t->{start}{redir_url}" target="_blank">pay</a>,
        <a href="/status/$trxid?testmode=$test">status</a>,
        <a href="/info/$trxid?testmode=$test">info</a>
    </tr>
__TRANS
    }

    $resp->content( <<__PAGE );
<html>
<body>
<h1>Sisow demo</h1>

<blockquote><font color="red">$errors</font></blockquote>

<form action="/" method="GET">
<p>User: $who</p>

<h2>iDEAL bank list</h2>

<input type="checkbox" name="testmode"$testmode
  onChange="submit()">&nbsp;Test<br>

<input type="submit" name="update_banks" value=" Update iDEAL bank list ">
(contains two minutes discouragement, be patient)

<h2>Start transaction</h2>

<table>
<tr><td>Bank:</td>
    <td><select name="bank">
@banksel</select></td></tr>

<tr><td>Amount</td>
    <td><input type="text" name="amount" value="0.00">&nbsp;&euro;</td></tr>

<tr><td>Invoice-nr</td>
    <td><input type="text" name="purchase_id" size="40"> (required)</td></tr>

<tr><td>Description</td>
    <td><input type="text" name="description" size="40"> (required)</td></tr>

<tr><td>Entrance&nbsp;code</td>
    <td><input type="text" name="entrance_code" size="40"> (optional)</td></tr>

<tr><td>&nbsp;</td>
    <td><input type="submit" name="start_trans" value=" Start new transaction "></td></tr>

</table>

<h3>Existing transactions</h3>

<table>
@trans
<tr><td colspan="4">&nbsp;</td>
    <td><input type="submit" name="refresh" value=" Refresh "></td>
    <td>&nbsp;</td></tr>
</table>


</form>

<pre>$x</pre>
</body>
</html>
__PAGE

    @errors = ();
    $resp;
}

sub add_log(@)          # not thread-safe
{   open my($log), '>>:encoding(utf8)', 'log'
        or return;
    $log->print(join '', @_, "\n");
}

sub update_banks($)
{   my $test  = shift;
    my @banks = try {$sisow->listIdealBanks(test => $test)};
    if($@)
    {   push @errors, $@;
        return;
    }

    my $outfn = 'bank_list';
    $outfn   .= '.test' if $test;

    open my($out), '>:encoding(utf8)', $outfn or return;
    $out->print(join '', map "$_->{id} $_->{name}\n", @banks);
    @banks;
}

sub start_trans($)
{   my ($qf) = @_;
    my $bank     = $qf->{bank};
    my ($prov, $bankid) = $bank =~ /[^0-9]/ ? ($bank, undef) : (ideal => $bank);

    my %params   =
     ( amount        => $qf->{amount}
     , payment       => $prov
     , bank_id       => $bankid
     , purchase_id   => $qf->{purchase_id}
     , description   => $qf->{description}
     , entrance_code => $qf->{entrance_code}
     , return_url    => $daemon->docroot."/notify"
     );

    #push @errors, Dumper \%params;
    my ($trxid, $redir_url) = try {$sisow->startTransaction(%params)};
    if($@)
    {   push @errors, $@->wasFatal;
        return;
    }

    push @errors, "Started transaction $trxid";
    if(open my($t), '>:encoding(utf8)', "t_$trxid")
    {   $params{start}    = +{trxid => $trxid, redir_url => $redir_url
          , stamp => scalar localtime()};
        $params{notifies} = [];
        $t->print(Dumper \%params);
        $t->close;
    }

    # Usually, you would automatically redirect the user to the bank-page,
    # but to be able to play with it, we only register it here.
    \%params;
}

sub read_banks($)
{   my ($test) = @_;

    my $infn   = 'bank_list';
    $infn     .= '.test' if $test;
    -f $infn or return ();
    sort {$a->[1] cmp $b->[1]} map {chomp; [split]} read_file $infn;
}

sub show_status($)
{   my ($fn) = @_;
    my $t    = do $fn or return;
    my $trxid = $t->{start}{trxid};
    push @errors, "Transaction $trxid status: "
                . $sisow->transactionStatus($trxid);
}

sub notify($)
{   my ($qf) = @_;
    #push @errors,  "NOTIFY ". Dumper $qf;
    my $trxid    = $qf->{trxid};
    my $fn       = "t_$trxid";
    my $t        = do $fn or return;

    $qf->{stamp} = localtime();
    push @{$t->{notifies}}, $qf;

    $sisow->securedPayment($qf)
        or push @errors, "checksum failed";

    if(open my($f), '>:encoding(utf8)', $fn)
    {   $f->print(Dumper $t);
        $f->close;
    }
}

sub show_info($)
{   my ($fn) = @_;
    my $t    = do $fn or return;
    my $trxid = $t->{start}{trxid};
    push @errors, "Transaction $trxid remote info:\n<pre>"
                . Dumper($sisow->transactionInfo($trxid)) . "</pre>\n";
    push @errors, "Transaction $trxid local info:\n<pre>".Dumper($t)."</pre>\n";
}

