package Net::IMP::Remote::DualvarMapping;

use strict;
use warnings;
use Net::IMP::Remote::Protocol;
use Net::IMP qw(:DEFAULT :log IMP_DATA_TYPES );
use Net::IMP::Debug;
use Exporter 'import';
our @EXPORT = qw(rpc_i2d rpc_d2i);

# data type mapping int -> dualvar
# basic data types are added, we check for more additional types in 
# IMPRPC_GET_INTERFACE and IMPRPC_SET_INTERFACE
my %dt_i2d = (
    IMP_DATA_STREAM+0 => IMP_DATA_STREAM,
    IMP_DATA_PACKET+0 => IMP_DATA_PACKET,
);

sub _dt_i2d {
    my $i = shift;
    my $v = $dt_i2d{$i};
    return $v if defined $v;
    for ( IMP_DATA_TYPES() ) {
	exists $dt_i2d{ $_+0 } and next;
	$dt_i2d{ $_+0 } = $_;
    }
    $v = $dt_i2d{$i};
    return $v if defined $v;
    die "cannot map $i to known data type";
}

# return type mapping int -> dualvar
my %rt_i2d = map { ( $_+0 => $_ ) } (
    IMP_PASS,
    IMP_PASS_PATTERN,
    IMP_PREPASS,
    IMP_DENY,
    IMP_DROP,
    IMP_FATAL,
    IMP_TOSENDER,
    IMP_REPLACE,
    IMP_REPLACE_LATER,
    IMP_PAUSE,
    IMP_CONTINUE,
    IMP_LOG,
    IMP_PORT_OPEN,
    IMP_PORT_CLOSE,
    IMP_ACCTFIELD,
);

# log level mapping int -> dualvar
my %ll_i2d = map { ( $_+0 => $_ ) } (
    IMP_LOG_DEBUG,
    IMP_LOG_INFO,
    IMP_LOG_NOTICE,
    IMP_LOG_WARNING,
    IMP_LOG_ERR,
    IMP_LOG_CRIT,
    IMP_LOG_ALERT,
    IMP_LOG_EMERG,
);

# op mapping int -> dualvar
my %op_i2d = map { ( $_+0 => $_ ) } (
    IMPRPC_GET_INTERFACE,
    IMPRPC_SET_INTERFACE,
    IMPRPC_NEW_ANALYZER,
    IMPRPC_DEL_ANALYZER,
    IMPRPC_DATA,
    IMPRPC_SET_VERSION,
    IMPRPC_EXCEPTION,
    IMPRPC_INTERFACE,
    IMPRPC_RESULT,
);

my %args_d2i = (
    IMPRPC_GET_INTERFACE+0 => sub {
	# @_ -> list< data_type_id, list<result_type_id> > provider_ifs
	my @rv;
	for my $if (@_) {
	    my ($dtype,$rtypes) = @$if;
	    if ( defined $dtype ) {
		$dt_i2d{ $dtype+0 } ||= $dtype;
		$dtype += 0
	    }
	    if ( $rtypes ) {
		push @rv, [ $dtype , [ map { $_+0 } @$rtypes ]];
	    } else {
		push @rv, [ $dtype ]
	    }
	}
	return @rv;
    },
    IMPRPC_SET_INTERFACE+0 => sub {
	# @_ ->  <data_type_id, list<result_type_id>> provider_if
	my ($dtype,$rtypes) = @{$_[0]};
	my @rt = map { $_+0 } @$rtypes;
	if ( ! defined $dtype ) {
	    return [ undef , \@rt ]
	} else {
	    $dt_i2d{ $dtype+0 } ||= $dtype;
	    return [ $dtype+0 , \@rt ]
	}
    },
    IMPRPC_DATA+0 => sub {
	# @_ -> analyzer_id, dir, offset, data_type_id, char data[]
	return (@_[0,1,2],$_[3]+0,$_[4]);
    },
    IMPRPC_RESULT+0 => sub {
	# @_ -> analyzer_id, result_type_id, ...
	my ($id,$rtype) = @_;
	if ( $rtype == IMP_LOG ) {
	    # id,type - dir,offset,len,level,msg,@extmsg
	    return ($id,$rtype+0,@_[2,3,4],$_[5]+0,@_[6..$#_]);
	} else {
	    return ($id,$rtype+0,@_[2..$#_]);
	}
    },
);
$args_d2i{ IMPRPC_INTERFACE+0 } = $args_d2i{ IMPRPC_GET_INTERFACE+0 };


my %args_i2d = (
    IMPRPC_GET_INTERFACE+0 => sub {
	# @_ -> list< data_type_id, list<result_type_id> > provider_ifs
	my @rv;
	for my $if (@_) {
	    my ($dtype,$rtypes) = @$if;
	    $dtype = $dt_i2d{$dtype} || _dt_i2d($dtype) if defined $dtype;
	    if ( $rtypes ) {
		push @rv, [ $dtype, [ map { $rt_i2d{$_} } @$rtypes ]];
	    } else {
		push @rv, [ $dtype ]
	    }
	}
	return @rv;
    },
    IMPRPC_SET_INTERFACE+0 => sub {
	# @_ ->  <data_type_id, list<result_type_id>> provider_if
	my ($dtype,$rtypes) = @{$_[0]};
	my @rt = map { defined($_) ? $rt_i2d{$_} :undef } @$rtypes;
	$dtype = $dt_i2d{$dtype} || _dt_i2d($dtype) if defined $dtype;
	return [ $dtype,\@rt ];
    },
    IMPRPC_DATA+0 => sub {
	# @_ -> analyzer_id, dir, offset, data_type_id, char data[]
	return (@_[0,1,2],$dt_i2d{$_[3]} || _dt_i2d($_[3]),$_[4]);
    },
    IMPRPC_RESULT+0 => sub {
	# @_ -> analyzer_id, result_type_id, ...
	my ($id,$rtype) = @_;
	if ( $rtype == IMP_LOG ) {
	    # id,type - dir,offset,len,level,msg,@extmsg
	    return ($id,$rt_i2d{$rtype},@_[2,3,4],$ll_i2d{$_[5]},@_[6..$#_]);
	} else {
	    return ($id,$rt_i2d{$rtype},@_[2..$#_]);
	}
    },
);
$args_i2d{ IMPRPC_INTERFACE+0 } = $args_i2d{ IMPRPC_GET_INTERFACE+0 };

sub rpc_i2d {
    my ($op,@args) = @{$_[0]};
    $op = $op_i2d{$op};
    my $sub = $args_i2d{$op+0} or return [$op,@args];
    #$DEBUG && debug("calling args_i2d for $op");
    return [ $op, $sub->(@args) ];
}

sub rpc_d2i {
    my ($op,@args) = @{$_[0]};
    my $sub = $args_d2i{$op+0} or return [ $op+0,@args ];
    #$DEBUG && debug("calling args_d2i for $op");
    return [ $op+0,$sub->(@args) ];
}

1;
