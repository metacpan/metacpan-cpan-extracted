package Net::Ethereum;

use 5.022000;
use strict;
use warnings;

use HTTP::Request;
use LWP::UserAgent;
use JSON;
use Math::BigInt;
use Math::BigFloat;
use Data::Dumper;

our $VERSION = '0.27';


=pod

=encoding utf8

=head1 NAME

  Net::Ethereum - Perl Framework for Ethereum JSON RPC API.

=head1 SYNOPSIS

  # Deploy contract

  use Net::Ethereum;

  my $contract_name = $ARGV[0];
  my $password = $ARGV[1];

  my $node = Net::Ethereum->new('http://localhost:8545/');
  $node->set_debug_mode(0);
  $node->set_show_progress(1);

  # my $src_account = "0x0f687ab2be314d311a714adde92fd9055df18b48";
  my $src_account = $node->eth_accounts()->[0];
  print 'My account: '.$src_account, "\n";

  my $constructor_params={};
  $constructor_params->{ initString } = '+ Init string for constructor +';
  $constructor_params->{ initValue } = 102; # init value for constructor

  my $contract_status = $node->compile_and_deploy_contract($contract_name, $constructor_params, $src_account, $password);
  my $new_contract_id = $contract_status->{contractAddress};
  my $transactionHash = $contract_status->{transactionHash};
  my $gas_used = hex($contract_status->{gasUsed});
  print "\n", 'Contract mined.', "\n", 'Address: '.$new_contract_id, "\n", 'Transaction Hash: '.$transactionHash, "\n";

  my $gas_price=$node->eth_gasPrice();
  my $contract_deploy_price = $gas_used * $gas_price;
  my $price_in_eth = $node->wei2ether($contract_deploy_price);
  print 'Gas used: '.$gas_used.' ('.sprintf('0x%x', $gas_used).') wei, '.$price_in_eth.' ether', "\n\n";


  # Contract sample

  pragma solidity ^0.4.10;

  contract HelloSol {
      string savedString;
      uint savedValue;
      address contractOwner;
      function HelloSol(uint initValue, string initString) public {
          contractOwner = msg.sender;
          savedString = initString;
          savedValue = initValue;
      }
      function setString( string newString ) public {
          savedString = newString;
      }
      function getString() public constant returns( string curString) {
          return savedString;
      }
      function setValue( uint newValue ) public {
          savedValue = newValue;
      }
      function getValue() public constant returns( uint curValue) {
          return savedValue;
      }
      function setAll(uint newValue, string newString) public {
          savedValue = newValue;
          savedString = newString;
      }
      function getAll() public constant returns( uint curValue, string curString) {
          return (savedValue, savedString);
      }
      function getAllEx() public constant returns( bool isOk, address msgSender, uint curValue, string curString, uint val1, string str1, uint val2, uint val3) {
          string memory sss="++ ==================================== ++";
          return (true, msg.sender, 33333, sss, 9999, "Line 9999", 7777, 8888);
      }

      function repiter(bool pBool, address pAddress, uint pVal1, string pStr1, uint pVal2, string pStr2, uint pVal3, int pVal4) public pure
      returns( bool rbBool, address rpAddress, uint rpVal1, string rpStr1, uint rpVal2, string rpStr2, uint rpVal3, int rpVal4) {
        return (pBool, pAddress, pVal1, pStr1, pVal2, pStr2, pVal3, pVal4);
      }
  }


  # Call contract contract_methods

  use Net::Ethereum;
  use Data::Dumper;

  my $contract_name = $ARGV[0];
  my $password = $ARGV[1];
  # my $src_account = "0x0f687ab2be314d311a714adde92fd9055df18b48";
  my $contract_id = $ARGV[2];;

  my $node = Net::Ethereum->new('http://localhost:8545/');
  $node->set_debug_mode(0);
  $node->set_show_progress(1);

  my $src_account = $node->eth_accounts()->[0];
  print 'My account: '.$src_account, "\n";

  my $abi = $node->_read_file('build/'.$contract_name.'.abi');
  $node->set_contract_abi($abi);
  $node->set_contract_id($contract_id);


  # Call contract methods without transactions

  my $function_params={};
  my $test1 = $node->contract_method_call('getValue', $function_params);
  print Dumper($test1);

  my $test = $node->contract_method_call('getString');
  print Dumper($test);

  my $testAll = $node->contract_method_call('getAll');
  print Dumper($testAll);

  my $testAllEx = $node->contract_method_call('getAllEx');
  print Dumper($testAllEx);

  $function_params={};
  $function_params->{ pBool } = 1;
  $function_params->{ pAddress } = "0xa3a514070f3768e657e2e574910d8b58708cdb82";
  $function_params->{ pVal1 } = 1111;
  $function_params->{ pStr1 } = "This is string 1";
  $function_params->{ pVal2 } = 222;
  $function_params->{ pStr2 } = "And this is String 2, very long string +++++++++++++++++=========";
  $function_params->{ pVal3 } = 333;
  $function_params->{ pVal4 } = '-999999999999999999999999999999999999999999999999999999999999999977777777';

  my $rc = $node->contract_method_call('repiter', $function_params);
  print Dumper($rc);


  # Send Transaction 1

  my $rc = $node->personal_unlockAccount($src_account, $password, 600);
  print 'Unlock account '.$src_account.'. Result: '.$rc, "\n";

  my $function_params={};
  $function_params->{ newString } = '+++ New string for save +++';

  my $used_gas = $node->contract_method_call_estimate_gas('setString', $function_params);
  my $gas_price=$node->eth_gasPrice();
  my $transaction_price = $used_gas * $gas_price;
  my $call_price_in_eth = $node->wei2ether($transaction_price);
  print 'Estimate Transaction Gas: '.$used_gas.' ('.sprintf('0x%x', $used_gas).') wei, '.$call_price_in_eth.' ether', "\n";

  my $tr = $node->sendTransaction($src_account, $node->get_contract_id(), 'setString', $function_params, $used_gas);

  print 'Waiting for transaction: ', "\n";
  my $tr_status = $node->wait_for_transaction($tr, 25, $node->get_show_progress());
  print Dumper($tr_status);


  # Send Transaction 2

  $rc = $node->personal_unlockAccount($src_account, $password, 600);
  print 'Unlock account '.$src_account.'. Result: '.$rc, "\n";

  $function_params={};
  $function_params->{ newValue } = 77777;

  $used_gas = $node->contract_method_call_estimate_gas('setValue', $function_params);

  $transaction_price = $used_gas * $gas_price;
  $call_price_in_eth = $node->wei2ether($transaction_price);
  print 'Estimate Transaction Gas: '.$used_gas.' ('.sprintf('0x%x', $used_gas).') wei, '.$call_price_in_eth.' ether', "\n";

  $tr = $node->sendTransaction($src_account, $node->get_contract_id(), 'setValue', $function_params, $used_gas);

  print 'Waiting for transaction: ', "\n";
  $tr_status = $node->wait_for_transaction($tr, 25, $node->get_show_progress());
  print Dumper($tr_status);


  $testAllEx = $node->contract_method_call('getAllEx');
  print Dumper($testAllEx);


  # Some other methods

  my $res = $node->eth_accounts();
  print Dumper($res);

  my $web3_version = $node->web3_clientVersion();
  print Dumper($web3_version);

  my $web3_sha3 = $node->web3_sha3("0x68656c6c6f20776f726c64");
  print Dumper($web3_sha3);

  my $net_version = $node->net_version();
  print Dumper($net_version);

  my $net_listening = $node->net_listening();
  print Dumper($net_listening);

  my $net_peerCount = $node->net_peerCount();
  print Dumper($net_peerCount);

  my $eth_protocolVersion = $node->eth_protocolVersion();
  print Dumper($eth_protocolVersion);

  my $eth_syncing = $node->eth_syncing();
  print Dumper($eth_syncing);

  my $eth_coinbase = $node->eth_coinbase();
  print Dumper($eth_coinbase);

  my $eth_mining = $node->eth_mining();
  print Dumper($eth_mining);

  my $eth_hashrate = $node->eth_hashrate();
  print Dumper($eth_hashrate);

  my $eth_gasPrice = $node->eth_gasPrice();
  print Dumper($eth_gasPrice);

  my $eth_blockNumber = $node->eth_blockNumber();
  print Dumper($eth_blockNumber);

  my $eth_getBalance = $node->eth_getBalance('0xa15862b34abfc4b423fe52f153c95d83f606cc97', "latest");
  print Dumper($eth_getBalance);

  my $eth_getTransactionCount = $node->eth_getTransactionCount('0xa15862b34abfc4b423fe52f153c95d83f606cc97', "latest");
  print Dumper($eth_getTransactionCount);

  my $eth_getBlockTransactionCountByHash = $node->eth_getBlockTransactionCountByHash('0xe79342277d7e95cedf0409e0887c2cddb3ebc5f0d952b9f7c1c1c5cef845cb97', "latest");
  print Dumper($eth_getBlockTransactionCountByHash);

  my $eth_getCode = $node->eth_getCode('0x11c63c5ebc2c6851111d881cb58c213c609c92d4', "latest");
  print Dumper($eth_getCode);



=head1 DESCRIPTION

  Net::Ethereum - Perl Framework for Ethereum JSON RPC API.

  This is alpha debugging version.

  Currently support marshaling only uint, int, bool, string types.

  Start node cmd:

  geth --datadir node1 --nodiscover --mine --minerthreads 1 --maxpeers 0 --verbosity 3 --networkid 98765 --rpc --rpcapi="db,eth,net,web3,personal,web3" console

  Attach node:

  geth --datadir node1 --networkid 98765 attach ipc://home/frolov/node1/geth.ipc



=head1 FUNCTIONS

=head2 new()

  my $node = Net::Ethereum->new('http://localhost:8545/');

=cut

sub new
{
  my ($this, $api_url) = @_;
  my $self = {};
  bless( $self, $this );

  $self->{api_url} = $api_url;
  $self->{abi} = {};
  $self->{debug} = 0;
  $self->{return_raw_data} = 0;
  $self->{show_progress} = 0;

  return $self;
}


=pod

=head2 web3_clientVersion

  Returns the current client version.
  my $web3_version = $node->web3_clientVersion();

=cut

sub web3_clientVersion()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "web3_clientVersion", params => [], id => 67};
  return $this->_node_request($rq)-> { result };
}

=pod

=head2 web3_sha3

  Returns Keccak-256 (not the standardized SHA3-256) of the given data.
  my $web3_sha3 = $node->web3_sha3("0x68656c6c6f20776f726c64");

=cut

sub web3_sha3()
{
  my ($this, $val) = @_;
  my $rq = { jsonrpc => "2.0", method => "web3_sha3", params => [ $val ], id => 64};
  return $this->_node_request($rq)-> { result };
}
=pod

=head2 net_version

  Returns the current network id:

=over

=item "1": Ethereum Mainnet
=item "2": Morden Testnet (deprecated)
=item "3": Ropsten Testnet
=item "4": Rinkeby Testnet
=item "42": Kovan Testnet

=back

  my $net_version = $node->net_version();

=cut

sub net_version()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "net_version", params => [], id => 67};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 net_listening

  Returns 1 (true) if client is actively listening for network connections.
  my $net_listening = $node->net_listening();

=cut

sub net_listening()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "net_listening", params => [], id => 67};
  my $rc = $this->_node_request($rq)-> { result };
  $rc ? return 1 : return 0;
}

=pod

=head2 net_peerCount

  Returns number of peers currently connected to the client.
  my $net_peerCount = $node->net_peerCount();

=cut

sub net_peerCount()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "net_peerCount", params => [], id => 74};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 personal_unlockAccount

  Decrypts the key with the given address from the key store.

  my $rc = $node->personal_unlockAccount($account, 'PASSWORD', 600);
  print 'Unlock account '.$src_account.'. Result: '.$rc, "\n";

  $account  - account to unlock;
  $password - passphrase;
  $timeout  - the unlock duration

  The unencrypted key will be held in memory until the unlock duration expires.
  The account can be used with eth_sign and eth_sendTransaction while it is unlocked.

=cut

sub personal_unlockAccount()
{
  my ($this, $account, $password, $timeout) = @_;
  my $rq = { jsonrpc => "2.0",method => "personal_unlockAccount", params => [ $account, $password, $timeout ], id => 1 };
  my $rc = $this->_node_request($rq);
  return $rc-> { result };
}


=pod

=head2 set_contract_abi

  Store contract ABI in this object

  my $node = Net::Ethereum->new('http://localhost:8545/');
  $node->set_contract_abi($src_abi);

=cut

sub set_contract_abi()
{
  my ($this, $abi_json) = @_;
  $this->{abi} =  decode_json($abi_json);
}

=pod

=head2 get_contract_abi

  Returns ABI for contract, stored in this object

  my $contract_abi = node->get_contract_abi();

=cut

sub get_contract_abi()
{
  my ($this) = @_;
  return $this->{abi};
}

=pod

=head2 set_debug_mode

  Set dubug mode. Debug info printed to console.
  $node->set_debug_mode($mode);

  $mode: 1 - debug on, 0 - debug off.

=cut

sub set_debug_mode()
{
  my ($this, $debug_mode) = @_;
  $this->{debug} = $debug_mode;
}


=pod

=head2 set_show_progress

  Set show progress mode to waiting contract deploying.
  $node->set_show_progress($mode);

  $mode: 1 - show progress mode on, 0 - show progress mode off.

=cut

sub set_show_progress()
{
  my ($this, $show_progress) = @_;
  $this->{show_progress} = $show_progress;
}

=pod

=head2 get_show_progress

  Get show progress mode to waiting contract deploying.
  $node->get_show_progress();

  Returns: 1 - show progress mode on, 0 - show progress mode off.

=cut

sub get_show_progress()
{
  my ($this) = @_;
  return $this->{show_progress};
}


=pod

=head2 set_contract_id

  Store contract Id in this object

  my $contract_id = "0x432e816769a2657029db98303e4946d7dedbcd8f";
  my $node = Net::Ethereum->new('http://localhost:8545/');
  $node->set_contract_id($contract_id);

  $contract_id - contract address

=cut

sub set_contract_id()
{
  my ($this, $contract_id) = @_;
  $this->{contract_id} = $contract_id;
}

=pod

=head2 get_contract_id

  Get contract id from this object
  Returns Contract id

  print 'New Contract id: '.$node->get_contract_id(), "\n";

=cut


sub get_contract_id()
{
  my ($this) = @_;
  return $this->{contract_id};
}


=pod

=head2 eth_protocolVersion

  Returns the current ethereum protocol version.

  my $eth_protocolVersion = $node->eth_protocolVersion();

=cut

sub eth_protocolVersion()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_protocolVersion", params => [], id => 67};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 eth_syncing

  Returns an object with data about the sync status or false.

  Object|Boolean, An object with sync status data or 0 (FALSE), when not syncing:

    startingBlock: QUANTITY - The block at which the import started (will only be reset, after the sync reached his head)
    currentBlock: QUANTITY - The current block, same as eth_blockNumber
    highestBlock: QUANTITY - The estimated highest block


  my $eth_syncing = $node->eth_syncing();

=cut

sub eth_syncing()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_syncing", params => [], id => 1};
  my $rc = $this->_node_request($rq)-> { result };
  if(!$rc)
  {
    return 0;
  }
  return $rc;
}

=pod

=head2 eth_coinbase

  Returns the client coinbase address (20 bytes - the current coinbase address).

  my $eth_coinbase = $node->eth_coinbase();

=cut

sub eth_coinbase()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_coinbase", params => [], id => 64};
  return $this->_node_request($rq)-> { result };
}

=pod

=head2 eth_mining

  Returns true if client is actively mining new blocks.

  my $eth_mining = $node->eth_mining();

=cut

sub eth_mining()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_mining", params => [], id => 71};
  my $rc = $this->_node_request($rq)-> { result };
  $rc ? return 1 : return 0;
}

=pod

=head2 eth_hashrate

  Returns the number of hashes per second that the node is mining with.

  my $eth_hashrate = $node->eth_hashrate();

=cut

sub eth_hashrate()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_hashrate", params => [], id => 71};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 eth_gasPrice

  Returns the current price per gas in wei.

  my $eth_gasPrice = $node->eth_gasPrice();

=cut

sub eth_gasPrice()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_gasPrice", params => [], id => 73};
  my $hex_string = $this->_node_request($rq)-> { result };
  my $dec = Math::BigInt->new($hex_string);
  return $dec;
}

=pod

=head2 eth_accounts

  Returns a list of addresses owned by client.

  my $res = $node->eth_accounts();

=cut

sub eth_accounts()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0",method => "eth_accounts", params => [], id => 1 };
  return $this->_node_request($rq)-> { result };
}

=pod

=head2 eth_blockNumber

  Returns the number of most recent block.

  my $eth_blockNumber = $node->eth_blockNumber();

=cut

sub eth_blockNumber()
{
  my ($this) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_blockNumber", params => [], id => 83};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 eth_getBalance

  Returns the balance of the account of given address as Math::BigInt object.

  $addr - address to check for balance;
  $block_number - integer block number, or the string "latest", "earliest" or "pending"

  my $eth_getBalance = $node->eth_getBalance('0xa15862b34abfc4b423fe52f153c95d83f606cc97', "latest");

=cut

sub eth_getBalance()
{
  my ($this, $addr, $block_number) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_getBalance", params => [ $addr, $block_number ], id => 1};
  my $hex_string = $this->_node_request($rq)-> { result };
  my $dec = Math::BigInt->new($hex_string);
  return $dec;
  #return $hex_string;
}


=pod

=head2 eth_getStorageAt

  ## TODO

=cut



=pod

=head2 eth_getTransactionCount

  Returns the number of transactions sent from an address.

  $addr - address;
  $block_number - integer block number, or the string "latest", "earliest" or "pending"

  my $eth_getTransactionCount = $node->eth_getTransactionCount('0xa15862b34abfc4b423fe52f153c95d83f606cc97', "latest");

=cut

sub eth_getTransactionCount()
{
  my ($this, $addr, $block_number) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_getTransactionCount", params => [ $addr, $block_number ], id => 1};
  my $num = $this->_node_request($rq)-> { result };
  my $dec = sprintf("%d", hex($num)) + 0;
  return $dec;
}

=pod

=head2 eth_getTransactionCount

  Returns the number of transactions in a block from a block matching the given block hash.

  $hash - hash of a block;

  my $eth_getBlockTransactionCountByHash = $node->eth_getBlockTransactionCountByHash('0xe79342277d7e95cedf0409e0887c2cddb3ebc5f0d952b9f7c1c1c5cef845cb97', "latest");

=cut

sub eth_getBlockTransactionCountByHash()
{
  my ($this, $hash) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_getBlockTransactionCountByHash", params => [ $hash ], id => 1};
  my $num = $this->_node_request($rq)-> { result };
  ##my $dec = sprintf("%d", hex($num)) + 0;
  return $num;
}


=pod

=head2 eth_getBlockTransactionCountByNumber

  ## TODO

=cut


=pod

=head2 eth_getUncleCountByBlockHash

  ## TODO

=cut

=pod

=head2 eth_getUncleCountByBlockNumber

  ## TODO

=cut




=pod

=head2 eth_getCode

  Returns code at a given address.

  my $contract_code=$node->eth_getCode($contract_status->{contractAddress}, "latest");

  $addr - address;
  $block_number - integer block number, or the string "latest", "earliest" or "pending"

  The following options are possible for the defaultBlock parameter:

    HEX String - an integer block number
    String "earliest" for the earliest/genesis block
    String "latest" - for the latest mined block
    String "pending" - for the pending state/transactions

=cut

sub eth_getCode()
{
  my ($this, $addr, $block_number) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_getCode", params => [ $addr, $block_number ], id => 1};
  return $this->_node_request($rq)-> { result };
}


=pod

=head2 eth_sign

  ## TODO

=cut



=pod

=head2 eth_sendTransaction

  Send message to contract.
  Returns result

  my $rc = $this->eth_sendTransaction($params);
  return $rc;

  $from - account;
  $to - contract id to send message;
  $data - marshalled data
  $gas - gas used

=cut

sub eth_sendTransaction()
{
  my ($this, $params) = @_;
  my $from = $params->{ from };
  my $to = $params->{ to };
  my $gas = $params->{ gas };
  my $data = $params->{ data };

  my $rq = { jsonrpc => "2.0", method => "eth_sendTransaction", params => [ { from => $from, to => $to, gas => $gas, data => $data } ], id => 1 };
  my $rc = $this->_node_request($rq);
  return $rc-> { result };
}


=pod

=head2 eth_sendRawTransaction

  ## TODO

=cut



=pod

=head2 eth_call

  Call contract method without transaction
  Returns result

  my $raw_params=$this->_marshal($function_name, $function_params);

  my $params = {};
  $params-> {to} = $this->{contract_id};
  $params-> {data} = $raw_params;
  my $rc = $this->eth_call($params);

=cut

sub eth_call()
{
  my ($this, $params) = @_;
  my $to = $params->{ to };
  my $data = $params->{ data };
  my $rq = { jsonrpc => "2.0", method => "eth_call", params => [ { to => $to, data => $data},"latest" ], id => 1 };
  return $this->_node_request($rq)-> { result };
}

=pod

=head2 eth_estimateGas

  Makes a call or transaction, which won't be added to the blockchain and returns the used gas, which can be used for estimating the used gas.
  Returns the amount of gas used.

  my $contract_used_gas = $node->deploy_contract_estimate_gas($src_account, $contract_binary);
  print 'Estimate GAS: ', Dumper($contract_used_gas);

  $params - See eth_call parameters, expect that all properties are optional.
  If no gas limit is specified geth uses the block gas limit from the pending block as an upper bound.
  As a result the returned estimate might not be enough to executed the call/transaction when the amount of gas is higher than the pending block gas limit.

  Returns the amount of gas used.

=cut

sub eth_estimateGas()
{
  my ($this, $params) = @_;
  my $to = $params->{ to };
  my $data = $params->{ data };
  my $rq = { jsonrpc => "2.0", method => "eth_estimateGas", params => [ { to => $to, data => $data} ], id => 1 };
  return $this->_node_request($rq)-> { result };
}


=pod

=head2 eth_getTransactionReceipt

  Returns the receipt of a transaction by transaction hash.
  That the receipt is not available for pending transactions.

  $tr_status = $this->eth_getTransactionReceipt($contrarc_deploy_tr);

=cut

sub eth_getTransactionReceipt()
{
  my ($this, $transaction_hash) = @_;
  my $rq = { jsonrpc => "2.0", method => "eth_getTransactionReceipt", params => [ $transaction_hash ], id => 1 };
  return $this->_node_request($rq);
}

=pod

=head2 wei2ether

  Convert wei to Ether, returns Ether

  my $price_in_eth = $node->wei2ether($contract_deploy_price);

=cut

sub wei2ether()
{
  my ($this, $wei) = @_;
  my $eth_in_wei = Math::BigFloat->new(1000000000000000000);
  my $wei_bigfloat = Math::BigFloat->new($wei);
  my $ether = $wei_bigfloat / $eth_in_wei;
  return $ether;
}


=pod

=head2 sendTransaction

  Send message to contract.
  Returns transaction id

  my $function_params={};
  $function_params->{ newString } = "+= test =+";
  my $tr = $node->sendTransaction($src_account, $node->get_contract_id(), 'setString', $function_params);

  $src_account - account;
  $contract_id - contract id to send message;
  $function_name - function name;
  $function_params - function params

=cut

sub sendTransaction()
{
  my ($this, $src_account, $contract_id, $function_name, $function_params, $gas) = @_;
  my $raw_params=$this->_marshal($function_name, $function_params);

  my $params = {};
  $params-> {from} = $src_account;
  $params-> {to} = $contract_id;
  $params-> {data} = $raw_params;
#  $params-> {gas} = "0xd312";
  $params-> {gas} = sprintf('0x%x', $gas);

  my $rc = $this->eth_sendTransaction($params);
  return $rc;
}


=pod

=head2 deploy_contract_estimate_gas

  Estimate used gas for deployed contract.
  Makes a call or transaction, which won't be added to the blockchain and returns the used gas, which can be used for estimating the used gas.
  Returns the amount of gas used.

  my $contract_used_gas = $node->deploy_contract_estimate_gas($src_account, $contract_binary);
  print 'Estimate GAS: ', Dumper($contract_used_gas);

  $src_account - account
  $contract_binary - contract binary code

=cut

sub deploy_contract_estimate_gas()
{
  my ($this, $src_account, $contract_binary, $constructor_params) = @_;

  my $params = {};
  $params-> {from} = $src_account;

  if($constructor_params)
  {
    my $raw_params=$this->_marshal('constructor', $constructor_params);
    $params-> {data} = $contract_binary.$raw_params;
  }
  else
  {
    $params-> {data} = $contract_binary;
  }

  #$params-> {data} = $contract_binary;
  return hex($this->eth_estimateGas($params));
}


=pod

=head2 deploy_contract

  Deploy contract
  Returns transaction id

  my $rc = $node->personal_unlockAccount($src_account, 'ptktysq', 600);
  print 'Unlock account '.$src_account.'. Result: '.$rc, "\n";
  my $contrarc_deploy_tr = $node->deploy_contract($src_account, $contract_binary);

  $src_account - account
  $contract_binary - contract binary code

=cut

sub deploy_contract()
{
  my ($this, $src_account, $contract_binary, $constructor_params, $gas) = @_;

  my $params = {};
  $params-> {from} = $src_account;
  if($constructor_params)
  {
    my $raw_params=$this->_marshal('constructor', $constructor_params);
    $params-> {data} = $contract_binary.$raw_params;
  }
  else
  {
    $params-> {data} = $contract_binary;
  }

  $params-> {gas} = sprintf('0x%x', $gas);
  my $rc = $this->eth_sendTransaction($params);
  return $rc;
}

=pod

=head2 wait_for_contract

  Wait for contract deployment/
  Store contract address into this object.
  Returns the transction status:

  $VAR1 = {
        'transactionIndex' => '0x0',
        'logs' => [],
        'contractAddress' => '0xa5e4b4aa28b79891f12ffa985b660ff222157659',
        'cumulativeGasUsed' => '0xb64b3',
        'to' => undef,
        'blockNumber' => '0x36a6',
        'blockHash' => '0x71b75f5eae70c532f94aeee91df0fef0df6208c451f6c007fe9a2a462fb23fc0',
        'transactionHash' => '0xfa71027cb3ae4ed05ec7a71d1c0cdad7d0dc501679e976caa0bf665b7309b97b',
        'from' => '0x0f687ab2be314d311a714adde92fd9055df18b48',
        'logsBloom' => '0x0000000...00',
        'gasUsed' => '0xb64b3',
        'root' => '0x9a32416741eb3192eae9197fc20acf7e5436fce7e6d92153aca91f92d373d41b'
      };


  my $contract_status = $node->wait_for_contract($contrarc_deploy_tr);

  $contrarc_deploy_tr - waiting contract transaction;
  $iterations - number of wait iterations;
  $show_progress - show progress on console (1 or 0)

=cut

sub wait_for_contract()
{
  my ($this, $contrarc_deploy_tr, $iterations, $show_progress) = @_;
  my $new_contract_id;
  my $tr_status;

  if($show_progress) { $| = 1; }
  for(my $i=0; $i<$iterations;$i++)
  {
    $tr_status = $this->eth_getTransactionReceipt($contrarc_deploy_tr);
    if($tr_status->{result})
    {
      $new_contract_id = $tr_status->{result}->{contractAddress};
      $this->set_contract_id($new_contract_id);
      if($show_progress) { print "\n"; }
      last;
    }
    sleep(5);
    if($show_progress) { print '.'.$i; }
  }
  return $tr_status->{result};
}

=pod

=head2 wait_for_transaction

  Wait for wait_for_transaction
  Returns the transction status:

  $VAR1 = {
         'cumulativeGasUsed' => '0xabcd',
          'transactionHash' => '0x237569eeae8f8f3da05d7bbd68066c18921406441dac8de13092c850addcb15b',
          'logs' => [],
          'gasUsed' => '0xabcd',
          'transactionIndex' => '0x0',
          'blockHash' => '0xdb7f3748658abdb60859e1097823630d7eb140448b40c8e1ac89170a76fc797e',
          'from' => '0x0f687ab2be314d311a714adde92fd9055df18b48',
          'logsBloom' => '0x000000000000000000...0000',
          'to' => '0x6f059b63aee6af50920d2a0fbd287cec94117826',
          'root' => '0x3fe46002e1c71876474a8b460222adb2309ab8f36b5750a6408a1f921f54ab4c',
          'blockNumber' => '0x36e2',
          'contractAddress' => undef
      };


  my $tr_status = $node->wait_for_transaction($tr);

  $contrarc_deploy_tr - waiting transaction;
  $iterations - number of wait iterations;
  $show_progress - show progress on console (1 or 0)

=cut

sub wait_for_transaction()
{
  my ($this, $contrarc_deploy_tr, $iterations, $show_progress) = @_;
  my $new_contract_id;
  my $tr_status;

  if($show_progress) { $| = 1; }
  for(my $i=0; $i<$iterations;$i++)
  {
    $tr_status = $this->eth_getTransactionReceipt($contrarc_deploy_tr);
    if($tr_status->{result})
    {
      if($show_progress) { print "\n"; }
      last;
    }
    sleep(5);
    if($show_progress) { print '.'.$i; }
  }
  return $tr_status->{result};
}


=pod

=head2 contract_method_call_estimate_gas

  Estimate used gas for contract method call.
  Makes a call or transaction, which won't be added to the blockchain and returns the used gas, which can be used for estimating the used gas.
  Returns the amount of gas used.

  my $function_params={};
  $function_params->{ newString } = '+= test GAS ok =+';

  my $used_gas = $node->contract_method_call_estimate_gas('setString', $function_params);
  print 'Estimate GAS: ', Dumper($used_gas);

=cut

sub contract_method_call_estimate_gas()
{
  my ($this, $function_name, $function_params) = @_;

  my $raw_params=$this->_marshal($function_name, $function_params);
  my $params = {};
  $params-> {to} = $this->{contract_id};
  $params-> {data} = $raw_params;
  return hex($this->eth_estimateGas($params));
}


=pod

=head2 contract_method_call

  Call contract method without transaction
  Returns unmarshalled data

  $function_params={};
  $function_params->{ pBool } = 1;
  $function_params->{ pAddress } = "0xa3a514070f3768e657e2e574910d8b58708cdb82";
  $function_params->{ pVal1 } = 11;
  $function_params->{ pStr1 } = "str1 This is string 1";
  $function_params->{ pVal2 } = 22;
  $function_params->{ pStr2 } = "str2 And this is String 2, very long string +++++++++++++++++== smart!";
  $function_params->{ pVal3 } = 33;
  $function_params->{ pVal4 } = 44;

  my $rc = $node->contract_method_call('repiter', $function_params);

=cut

sub contract_method_call()
{
  my ($this, $function_name, $function_params) = @_;
  my $raw_params=$this->_marshal($function_name, $function_params);

  my $params = {};
  $params-> {to} = $this->{contract_id};
  $params-> {data} = $raw_params;

  if($this->{debug})
  {
    print 'Function name: '.$function_name. "\n";
    print 'Function params: ', Dumper($function_params);
    print 'Function raw params: ', Dumper($params);
  }

  my $rc = $this->eth_call($params);

  if($this->{debug})
  {
    print 'eth_call return data: '.$rc. "\n";
  }
  my $raw_data = substr($rc, 2);
  return $this->_unmarshal($function_name, $raw_data);
}


=pod

=head2 compile_and_deploy_contract

  Compile and deploy contract
  Returns contract id

  my $constructor_params={};
  $constructor_params->{ initString } = '+ from constructor +';
  $constructor_params->{ initValue } = 101;

  my $contract_status = $node->compile_and_deploy_contract($contract_name, $constructor_params, $src_account, $password);
  my $new_contract_id = $contract_status->{contractAddress};

=cut

sub compile_and_deploy_contract()
{
  my ($this, $contract_name, $constructor_params, $src_account, $password) = @_;

  my $contract_src_path = $contract_name.'.sol';
  my $bin_solc = '/usr/bin/solc';
  my $cmd = "$bin_solc --bin --abi $contract_src_path -o build --overwrite";
  if(system($cmd))
  {
    die sprintf("Failed to compile $contract_name with value %d\n", $? >> 8);
  }

  my $abi = $this->_read_file('build/'.$contract_name.'.abi');
  $this->set_contract_abi($abi);
  my $bin = $this->_read_file('build/'.$contract_name.'.bin');
  $bin = '0x'.$bin;

  $this->personal_unlockAccount($src_account, $password, 600);

  my $contract_used_gas = $this->deploy_contract_estimate_gas($src_account, $bin, $constructor_params);
  my $gas_price=$this->eth_gasPrice();
  my $contract_deploy_price = $contract_used_gas * $gas_price;
  my $price_in_eth = $this->wei2ether($contract_deploy_price);

#  print 'Estimate Contract GAS: '.$contract_used_gas.' wei ('.sprintf('0x%x', $contract_used_gas).' wei), $price_in_eth: '.$price_in_eth.' ether', "\n";

  my $contrarc_deploy_tr = $this->deploy_contract($src_account, $bin, $constructor_params, $contract_used_gas);
  my $contract_status = $this->wait_for_contract($contrarc_deploy_tr, 25, $this->{show_progress});

  my $contract_code=$this->eth_getCode($contract_status->{contractAddress}, "latest");
  if($contract_code eq '0x')
  {
    die 'Error: no contract code from network'.$contract_code;
  }
  return $contract_status;
}



# ==========================


=pod

=head2 _read_file

  Read file into variable.

  $file_path - path to file.

  my $abi = $this->_read_file('build/'.$contract_name.'.abi');
  $this->set_contract_abi($abi);
  my $bin = $this->_read_file('build/'.$contract_name.'.bin');

=cut

sub _read_file()
{
  my ($this, $file_path) = @_;
  open my $FILE, "<", $file_path or die "Can't open file: $!\n";
  local $/ = undef;
  my $content = <$FILE>;
  close $FILE;
  return $content;
}

=pod

=head2 _marshal

  nternal method.
  Marshaling data from from function params/
  Returns raw marshalled data

  my $raw_params=$this->_marshal($function_name, $function_params);

  $function_name - method name to get ABI
  $function_params - function params

=cut

sub _marshal()
{
  my ($this, $function_name, $function_params) = @_;

  my $function_abi;

  if($function_name eq 'constructor')
  {
    $function_abi = $this->_get_constructor_abi($function_name);
  }
  else
  {
    $function_abi = $this->_get_function_abi($function_name);
  }

  my $function_inputs = $function_abi-> { inputs };

  my $current_out_param_position=0;
  my $param_types_list="";
  my $encoded_arguments="";

  my $out_param_array=[];
  my $out_param_array_counter=0;

  # First pass

  foreach my $out_param (@$function_inputs)
  {
    my $cur_param_name = $out_param->{name};
    my $cur_param_type = $out_param->{type};
    $param_types_list .= $cur_param_type.',';

    if($cur_param_type eq 'bool' || $cur_param_type =~ m/^uint/i)
    {
      my $add_hunk=$function_params->{ $cur_param_name };
      $add_hunk=$this->_marshal_int($add_hunk);
      $out_param_array->[$out_param_array_counter] = $add_hunk;
      $out_param_array_counter++;
      $current_out_param_position += 64;
    }
    elsif($cur_param_type =~ m/^int/i)
    {
      my $add_hunk=$function_params->{ $cur_param_name };
      $add_hunk=$this->_marshal_int($add_hunk);
      $out_param_array->[$out_param_array_counter] = $add_hunk;
      $out_param_array_counter++;
      $current_out_param_position += 64;
    }
    elsif($cur_param_type eq 'address')
    {
      my $add_hunk=$function_params->{ $cur_param_name };
      $add_hunk=substr($add_hunk, 2);
      $add_hunk = sprintf('%064s', $add_hunk);
      $out_param_array->[$out_param_array_counter] = $add_hunk;
      $out_param_array_counter++;
      $current_out_param_position += 64;
    }
    elsif($cur_param_type eq 'string')
    {
      $current_out_param_position += 64;
      my $str=$function_params->{ $cur_param_name };
      my $str_length = length($str);
      $out_param_array->[$out_param_array_counter] = $str_length; # replace with data hunk offset into second pass
      $out_param_array_counter++;
      $current_out_param_position += 64;
    }
    else
    {
      die 'Net::Ethereum _marshal does not support type: '.$cur_param_type;
    }
  }

# Second pass

  my $var_data_offset_index = $out_param_array_counter;
  my $var_data_offset = $var_data_offset_index * 32;
  my $array_index=0;
  my $second_pass_counter=0;

  foreach my $out_param (@$function_inputs)
  {
    my $cur_param_name = $out_param->{name};
    my $cur_param_type = $out_param->{type};

    if($cur_param_type eq 'bool' || $cur_param_type =~ m/^uint/i)
    {
      $array_index++;
    }
    elsif($cur_param_type =~ m/^int/i)
    {
      $array_index++;
    }
     elsif($cur_param_type eq 'address')
    {
      $array_index++;
    }
    elsif($cur_param_type eq 'string')
    {
      my $str=$function_params->{ $cur_param_name };
      my $hunk=$this->_string2hex($str);
      my $hunk_size = length($hunk);
      my $number_of_32b_blocks = int($hunk_size / 64);
      my $part = $hunk_size % 64;
      my $repeater = '0'x(64-$part + 2);
      my $hunk_appended = substr($hunk.$repeater, 2);
      my $str_length = length($str);

      $out_param_array->[$array_index] = sprintf('%064x', $var_data_offset);
      $var_data_offset += (($number_of_32b_blocks+1) * 32) + 32;
      $array_index++;
      $out_param_array->[$var_data_offset_index + $second_pass_counter] = sprintf('%064x', $str_length);
      $second_pass_counter++;

      my $hunk_position=0;
      while(1)
      {
        my $cur_str=substr($hunk_appended, $hunk_position, 64);
        if($cur_str eq "")
        {
          last;
        }
        $out_param_array->[$var_data_offset_index + $second_pass_counter] = $cur_str;
        $second_pass_counter++;
        $hunk_position += 64;
      }
    }
  }

  my $raw;
  if($function_name eq 'constructor')
  {
    $raw=join('', @$out_param_array);
  }
  else
  {
    # Get Contract Method Id
    my $function_selector = $function_name;
    chop($param_types_list);
    $function_selector = $function_selector.'('.$param_types_list.')';
    my $contract_method_id = $this->_getContractMethodId($function_selector);
    $raw=$contract_method_id.join('', @$out_param_array);
  }
  return $raw;
}


=pod

=head2 _unmarshal

  Internal method.
  Unmarshal data from JSON RPC call

  return $this->_unmarshal($function_name, $raw_data);

  $function_name - method name to get ABI
  $raw_data - data, returned from method

=cut

sub _unmarshal()
{
  my ($this, $function_name, $raw_data) = @_;

  my $function_abi = $this->_get_function_abi($function_name);
  my $function_outputs = $function_abi-> { outputs };

  my $return_value={};
  if($this->{return_raw_data})
  {
    $return_value-> { raw_data } = $raw_data;
  }

  my $current_out_param_position=0;

  foreach my $out_param (@$function_outputs)
  {
    my $cur_param_name = $out_param->{name};
    my $cur_param_type = $out_param->{type};

    if($cur_param_type eq 'bool' || $cur_param_type =~ m/^uint/i)
    {
      my $hunk='0x'.substr($raw_data, $current_out_param_position, 64);
      my $uint256 = $this->_unmarshal_int($hunk);
      $return_value->{ $cur_param_name } = $uint256;
      $current_out_param_position += 64;
    }
    elsif($cur_param_type =~ m/^int/i)
    {
      my $hunk='0x'.substr($raw_data, $current_out_param_position, 64);
      my $uint256 = $this->_unmarshal_int($hunk);
      $return_value->{ $cur_param_name } = $uint256;
      $current_out_param_position += 64;

    }
    elsif($cur_param_type eq 'address')
    {
      my $hunk='0x'.substr($raw_data, $current_out_param_position, 64);
      $hunk =~ s/00//g;
      $return_value->{ $cur_param_name } = $hunk;
      $current_out_param_position += 64;
    }
    elsif($cur_param_type eq 'string')
    {
      my $size_offset = hex('0x'.substr($raw_data, $current_out_param_position, 64));
      my $data_size = hex(substr($raw_data, $size_offset * 2, 64));
      my $data_chunk = substr($raw_data, 64 + $size_offset*2, $data_size * 2);
      my $str = $this->_hex2string('0x'.$data_chunk);
      $return_value->{ $cur_param_name } = $str;
      $current_out_param_position += 64;
    }
    else
    {
      die 'Net::Ethereum _marshal does not support type: '.$cur_param_type;
    }
  }
  return $return_value;
}

=pod

=head2 _marshal_int

  Internal method.
  Marshal integer value
  Returns marshales string

  $add_hunk=$this->_marshal_int($add_hunk);

  int_to_marshal - int value to marshal

=cut

sub _marshal_int($$)
{
  my ($this, $int_to_marshal) = @_;
  my $bint_hex;
  my $filler_size;
  my $filler_char;

  my $bint = Math::BigInt->new($int_to_marshal);
  if($bint->is_negative())
  {
    $bint->bneg();
    $bint->bxor('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
    $bint->binc();
    $filler_char = 'f';
  }
  else
  {
    $filler_char = '0';
  }
  $bint_hex = $bint->to_hex();
  $filler_size = 64 - length($bint_hex);
  for(1..$filler_size)
  {
    $bint_hex = $filler_char.$bint_hex;
  }
  return($bint_hex);
}

=pod

=head2 _unmarshal_int

  Internal method.
  Unmarshal integer value
  Returns unmarshaled value

  my $uint256 = $this->_unmarshal_int($hunk);

  int_to_marshal - int value to marshal

=cut

sub _unmarshal_int($$)
{
  my ($this, $str_to_unmarshal) = @_;
  my $unmarshalled_int = Math::BigInt->new($str_to_unmarshal);
  my $neg_test = Math::BigInt->new($str_to_unmarshal);
  if($neg_test->band('0x8000000000000000000000000000000000000000000000000000000000000000'))
  {
    $unmarshalled_int->bxor('0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF');
    $unmarshalled_int->binc();
    $unmarshalled_int->bneg();
  }
  return $unmarshalled_int;
}

=pod

=head2 _get_function_abi

  Internal method.
  Returns ABI for given method

  my $function_abi = $this->_get_function_abi($function_name);

  $function_name - method name to get ABI

=cut

sub _get_function_abi()
{
  my ($this, $function_name) = @_;
  my $rec;
  my $abi = $this->{abi};
  foreach $rec (@$abi)
  {
    if($rec->{ type } eq 'function' and $rec->{ name } eq $function_name)
    {
      return $rec;
    }
  }
  return {};
}


=pod

=head2 _get_constructor_abi

  Internal method.
  Returns ABI for contract constructor

  if($function_name eq 'constructor')
  {
    $function_abi = $this->_get_constructor_abi($function_name);
  }

  $function_name - method name to get ABI

=cut

sub _get_constructor_abi()
{
  my ($this, $function_name) = @_;
  my $rec;
  my $abi = $this->{abi};

  foreach $rec (@$abi)
  {
    if($rec->{ type } eq 'constructor')
    {
      return $rec;
    }
  }
  return {};
}


=pod

=head2 _getContractMethodId

  Internal method.
  Convert a method name into function selector (contract methos id).
  Returns the contract methos id.

  The first four bytes of the call data for a function call specifies the function to be called.
  It is the first (left, high-order in big-endian) four bytes of the Keccak (SHA-3) hash of the signature of the function.
  The signature is defined as the canonical expression of the basic prototype, i.e. the function name with the parenthesised list of parameter types.
  Parameter types are split by a single comma - no spaces are used.

  my $function_selector = $function_name;
  chop($param_types_list);
  $method_name = $function_selector.'('.$param_types_list.')';
  my $contract_method_id = $this->_getContractMethodId($method_name);

  $method_name - function name, include parameters

=cut

sub _getContractMethodId()
{
  my ($this, $method_name) = @_;
  my $method_name_hex = $this->_string2hex($method_name);
  my $hash = $this->web3_sha3($method_name_hex);
  return substr($hash, 0, 10);
}

=pod

=head2 _hex2string

  Internal method.
  Convert a hexadecimal value into string. Returns the string.

  my $str = $this->_hex2string('0x'.$data_chunk);

  $data_chunk - hexadecimal data to conv

=cut

sub _hex2string()
{
  my ($this, $hex) = @_;

  my $n = 2;    # $n is group size.
  my @groups = unpack "a$n" x (length( $hex ) /$n ), $hex;
  my $string = join ('', map { chr(hex($_)) } @groups );
  return($string);
}


=pod

=head2 _string2hex

  Internal method.
  Convert a string to hexadecimal. Returns the converted string.

  my $hunk=$this->_string2hex($str);

  $string - source string to conv

=cut

sub _string2hex()
{
  my ($this, $string) = @_;
  my @array = split('', $string);
  my @array_ascii = map { sprintf("%x", ord($_)) } @array;
  my $string_ascii = join('', @array_ascii);
  return '0x'.$string_ascii;
}


=pod

=head2 _node_request

  Internal method.
  Send request to JSON RPC API

  my $rq = { jsonrpc => "2.0", method => "net_version", params => [], id => 67};
  my $num = $this->_node_request($rq)-> { result };

=cut

sub _node_request()
{
  my ($this, $json_data) = @_;
  my $req = HTTP::Request->new(POST => $this->{api_url});
  $req->header('Content-Type' => 'application/json');
  my $ua = LWP::UserAgent->new;
  my $data = encode_json($json_data);
  $req->add_content_utf8($data);
  my $ua_rc = $ua->request($req)->{ _content };

  my $rc;
  if($ua_rc=~/"result":/)
  {
    $rc = JSON::decode_json($ua_rc);
  }
  else
  {
    die 'Died at Net::Ethereum _node_request() - '.$ua_rc;
  }
  # my $rc = JSON::decode_json($ua->request($req)->{ _content });
  if($rc->{error}) { die $rc; }
  else { return $rc;  }
}



1;
__END__


=head1 SEE ALSO

=over 12

=item 1

JSON RPC API:
L<https://github.com/ethereum/wiki/wiki/JSON-RPC>

=item 2

Management APIs:
L<https://github.com/ethereum/go-ethereum/wiki/Management-APIs>

=item 3

Application Binary Interface Specification:
L<https://solidity.readthedocs.io/en/develop/abi-spec.html>

=item 4

Working with Smart Contracts through the Ethereum RPC API (Russian):
L<https://habrahabr.ru/company/raiffeisenbank/blog/338172/>

=back

=head1 AUTHOR

    Alexandre Frolov, frolov@itmatrix.ru

    L<https://www.facebook.com/frolov.shop2you>
    The founder and director of SAAS online store service Shop2YOU, L<http://www.shop2you.ru>

=head1 COPYRIGHT AND LICENSE

    Copyright (C) 2018 by Alexandre Frolov

    This library is free software; you can redistribute it and/or modify
    it under the same terms as Perl itself, either Perl version 5.26.0 or,
    at your option, any later version of Perl 5 you may have available.


=cut
