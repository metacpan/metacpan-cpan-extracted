use 5.010;

use Mojo::IOLoop::Delay;
use Mojo::CloudCheckr;

my $cc = Mojo::CloudCheckr->new(access_key => '...');

my %filter = (start => '2017-04-01', end => '2017-04-30', saved_filter_name => 'Monthly DBR');
say join "\t", "CloudCheckr ID", "Account Name", "AWS ID", "Bill";
Mojo::IOLoop->delay(
  sub {
    my $delay = shift;
    $cc->get(account => 'get_accounts_v2' => $delay->begin);
  },
  sub {
    my ($delay, $accounts) = @_;
    $delay->data(accounts => $accounts->result->json('/accounts_and_users'));
    foreach my $account ( @{$accounts->result->json('/accounts_and_users')} ) {
      my ($id) = $account->{cc_account_id} =~ s/\,//gr;
      $cc->get(billing => 'get_detailed_billing_with_grouping_v2', use_cc_account_id => $id, %filter => $delay->begin);
    }
  },
  sub {
    my ($delay, @accounts) = @_;
    my $accounts = $delay->data('accounts');
    for ( 0..$#accounts ) {
      my $account = $accounts->[$_];
      say join "\t", $account->{cc_account_id}, $account->{account_name}, $account->{aws_account_id}, sprintf("%.2f", $accounts[$_]->result->json('/Total'));
    }
  },
)->wait;
