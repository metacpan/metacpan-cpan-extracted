# Poloniex-API

**Poloniex API wrapper for perl**

**API DOCUMENTATION**
https://poloniex.com/support/api/

![perl](https://img.shields.io/cpan/l/Config-Augeas.svg)

## Usage:
```perl
	use Poloniex::API; 
	
	my $api = Poloniex::API->new(
		APIKey => 'your-api-key',
		Secret => 'your-secret-key'
	);
```

**public api**
```perl
	my $Ticker = $api->api_public('returnTicker');
	
	my $ChartData    = $api->api_public('returnChartData', {
		currencyPair => 'BTC_XMR',
		start        => 1405699200,
		end          => 9999999999,
		period       => 14400
	});
```

**trading api**
```perl
	my $returnCompleteBalances = $api->api_trading('returnCompleteBalances');
	my ($returnTradeHistory, $err) = $api->api_trading('returnTradeHistory', {
		currencyPair => 'BTC_ZEC'
	});
	
	if ($err) {
		say $returnTradeHistory->{error};
	}
```