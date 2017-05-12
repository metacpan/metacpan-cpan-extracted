
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Finance::TA;

@EXPORT_OK  = qw( PDL::PP ta_bbands PDL::PP ta_dema PDL::PP ta_ema PDL::PP ta_ht_trendline PDL::PP ta_kama PDL::PP ta_ma PDL::PP ta_mama PDL::PP ta_mavp PDL::PP ta_midpoint PDL::PP ta_midprice PDL::PP ta_sar PDL::PP ta_sarext PDL::PP ta_sma PDL::PP ta_t3 PDL::PP ta_tema PDL::PP ta_trima PDL::PP ta_wma PDL::PP ta_atr PDL::PP ta_natr PDL::PP ta_trange PDL::PP ta_adx PDL::PP ta_adxr PDL::PP ta_apo PDL::PP ta_aroon PDL::PP ta_aroonosc PDL::PP ta_bop PDL::PP ta_cci PDL::PP ta_cmo PDL::PP ta_dx PDL::PP ta_macd PDL::PP ta_macdext PDL::PP ta_macdfix PDL::PP ta_mfi PDL::PP ta_minus_di PDL::PP ta_minus_dm PDL::PP ta_mom PDL::PP ta_plus_di PDL::PP ta_plus_dm PDL::PP ta_ppo PDL::PP ta_roc PDL::PP ta_rocp PDL::PP ta_rocr PDL::PP ta_rocr100 PDL::PP ta_rsi PDL::PP ta_stoch PDL::PP ta_stochf PDL::PP ta_stochrsi PDL::PP ta_trix PDL::PP ta_ultosc PDL::PP ta_willr PDL::PP ta_ht_dcperiod PDL::PP ta_ht_dcphase PDL::PP ta_ht_phasor PDL::PP ta_ht_sine PDL::PP ta_ht_trendmode PDL::PP ta_ad PDL::PP ta_adosc PDL::PP ta_obv PDL::PP ta_cdl2crows PDL::PP ta_cdl3blackcrows PDL::PP ta_cdl3inside PDL::PP ta_cdl3linestrike PDL::PP ta_cdl3outside PDL::PP ta_cdl3starsinsouth PDL::PP ta_cdl3whitesoldiers PDL::PP ta_cdlabandonedbaby PDL::PP ta_cdladvanceblock PDL::PP ta_cdlbelthold PDL::PP ta_cdlbreakaway PDL::PP ta_cdlclosingmarubozu PDL::PP ta_cdlconcealbabyswall PDL::PP ta_cdlcounterattack PDL::PP ta_cdldarkcloudcover PDL::PP ta_cdldoji PDL::PP ta_cdldojistar PDL::PP ta_cdldragonflydoji PDL::PP ta_cdlengulfing PDL::PP ta_cdleveningdojistar PDL::PP ta_cdleveningstar PDL::PP ta_cdlgapsidesidewhite PDL::PP ta_cdlgravestonedoji PDL::PP ta_cdlhammer PDL::PP ta_cdlhangingman PDL::PP ta_cdlharami PDL::PP ta_cdlharamicross PDL::PP ta_cdlhighwave PDL::PP ta_cdlhikkake PDL::PP ta_cdlhikkakemod PDL::PP ta_cdlhomingpigeon PDL::PP ta_cdlidentical3crows PDL::PP ta_cdlinneck PDL::PP ta_cdlinvertedhammer PDL::PP ta_cdlkicking PDL::PP ta_cdlkickingbylength PDL::PP ta_cdlladderbottom PDL::PP ta_cdllongleggeddoji PDL::PP ta_cdllongline PDL::PP ta_cdlmarubozu PDL::PP ta_cdlmatchinglow PDL::PP ta_cdlmathold PDL::PP ta_cdlmorningdojistar PDL::PP ta_cdlmorningstar PDL::PP ta_cdlonneck PDL::PP ta_cdlpiercing PDL::PP ta_cdlrickshawman PDL::PP ta_cdlrisefall3methods PDL::PP ta_cdlseparatinglines PDL::PP ta_cdlshootingstar PDL::PP ta_cdlshortline PDL::PP ta_cdlspinningtop PDL::PP ta_cdlstalledpattern PDL::PP ta_cdlsticksandwich PDL::PP ta_cdltakuri PDL::PP ta_cdltasukigap PDL::PP ta_cdlthrusting PDL::PP ta_cdltristar PDL::PP ta_cdlunique3river PDL::PP ta_cdlupsidegap2crows PDL::PP ta_cdlxsidegap3methods PDL::PP ta_beta PDL::PP ta_correl PDL::PP ta_linearreg PDL::PP ta_linearreg_angle PDL::PP ta_linearreg_intercept PDL::PP ta_linearreg_slope PDL::PP ta_stddev PDL::PP ta_tsf PDL::PP ta_var PDL::PP ta_avgprice PDL::PP ta_medprice PDL::PP ta_typprice PDL::PP ta_wclprice );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::Finance::TA::VERSION = 0.008;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Finance::TA $VERSION;




=head1 NAME

PDL::Finance::TA - Technical Analysis Library (http://ta-lib.org) bindings for PDL

=head1 SYNOPSIS

 use PDL;
 use PDL::Finance::TA;

 # first load market data you want to analyze
 my $open   = ... ; # 1D piddle
 my $high   = ... ; # 1D piddle
 my $low    = ... ; # 1D piddle
 my $close  = ... ; # 1D piddle
 my $volume = ... ; # 1D piddle

 my $period = 20;
 my $moving_average = ta_sma($close, $period);
 my $money_flow_index = ta_mfi($high, $low, $close, $volume, $period);
 # both $moving_average and $money_flow_index are 1D piddles

=head1 DESCRIPTION

TA-Lib library - L<http://ta-lib.org> - is a multi-platform tool for market analysis. TA-Lib is widely used by trading
software developers requiring to perform technical analysis of financial market data.

This module provides an L<PDL|PDL> interface for TA-Lib library. It combines rich TA-Lib functionality with excelent
L<PDL|PDL> performance of handling huge data.

If you are not a L<PDL|PDL> user you might be interested in L<Finance::TA|Finance::TA> module which provides approximately
the same set of functions working with common perl data structures (which is fine if you are not about to process large
data sets and if you generally do not worry about performace).

=head1 FUNCTION INDEX

=head2 Group: Overlap Studies

L<ta_bbands|/ta_bbands> (Bollinger Bands), L<ta_dema|/ta_dema> (Double Exponential Moving Average), L<ta_ema|/ta_ema> (Exponential Moving Average), L<ta_ht_trendline|/ta_ht_trendline> (Hilbert Transform - Instantaneous Trendline), L<ta_kama|/ta_kama> (Kaufman Adaptive Moving Average), L<ta_ma|/ta_ma> (Moving average), L<ta_mama|/ta_mama> (MESA Adaptive Moving Average), L<ta_mavp|/ta_mavp> (Moving average with variable period), L<ta_midpoint|/ta_midpoint> (MidPoint over period), L<ta_midprice|/ta_midprice> (Midpoint Price over period), L<ta_sar|/ta_sar> (Parabolic SAR), L<ta_sarext|/ta_sarext> (Parabolic SAR - Extended), L<ta_sma|/ta_sma> (Simple Moving Average), L<ta_t3|/ta_t3> (Triple Exponential Moving Average (T3)), L<ta_tema|/ta_tema> (Triple Exponential Moving Average), L<ta_trima|/ta_trima> (Triangular Moving Average), L<ta_wma|/ta_wma> (Weighted Moving Average)

=head2 Group: Volatility Indicators

L<ta_atr|/ta_atr> (Average True Range), L<ta_natr|/ta_natr> (Normalized Average True Range), L<ta_trange|/ta_trange> (True Range)

=head2 Group: Momentum Indicators

L<ta_adx|/ta_adx> (Average Directional Movement Index), L<ta_adxr|/ta_adxr> (Average Directional Movement Index Rating), L<ta_apo|/ta_apo> (Absolute Price Oscillator), L<ta_aroon|/ta_aroon> (Aroon), L<ta_aroonosc|/ta_aroonosc> (Aroon Oscillator), L<ta_bop|/ta_bop> (Balance Of Power), L<ta_cci|/ta_cci> (Commodity Channel Index), L<ta_cmo|/ta_cmo> (Chande Momentum Oscillator), L<ta_dx|/ta_dx> (Directional Movement Index), L<ta_macd|/ta_macd> (Moving Average Convergence/Divergence), L<ta_macdext|/ta_macdext> (MACD with controllable MA type), L<ta_macdfix|/ta_macdfix> (Moving Average Convergence/Divergence Fix 12/26), L<ta_mfi|/ta_mfi> (Money Flow Index), L<ta_minus_di|/ta_minus_di> (Minus Directional Indicator), L<ta_minus_dm|/ta_minus_dm> (Minus Directional Movement), L<ta_mom|/ta_mom> (Momentum), L<ta_plus_di|/ta_plus_di> (Plus Directional Indicator), L<ta_plus_dm|/ta_plus_dm> (Plus Directional Movement), L<ta_ppo|/ta_ppo> (Percentage Price Oscillator), L<ta_roc|/ta_roc> (Rate of change : ((price/prevPrice)-1)*100), L<ta_rocp|/ta_rocp> (Rate of change Percentage: (price-prevPrice)/prevPrice), L<ta_rocr|/ta_rocr> (Rate of change ratio: (price/prevPrice)), L<ta_rocr100|/ta_rocr100> (Rate of change ratio 100 scale: (price/prevPrice)*100), L<ta_rsi|/ta_rsi> (Relative Strength Index), L<ta_stoch|/ta_stoch> (Stochastic), L<ta_stochf|/ta_stochf> (Stochastic Fast), L<ta_stochrsi|/ta_stochrsi> (Stochastic Relative Strength Index), L<ta_trix|/ta_trix> (1-day Rate-Of-Change (ROC) of a Triple Smooth EMA), L<ta_ultosc|/ta_ultosc> (Ultimate Oscillator), L<ta_willr|/ta_willr> (Williams' %R)

=head2 Group: Cycle Indicators

L<ta_ht_dcperiod|/ta_ht_dcperiod> (Hilbert Transform - Dominant Cycle Period), L<ta_ht_dcphase|/ta_ht_dcphase> (Hilbert Transform - Dominant Cycle Phase), L<ta_ht_phasor|/ta_ht_phasor> (Hilbert Transform - Phasor Components), L<ta_ht_sine|/ta_ht_sine> (Hilbert Transform - SineWave), L<ta_ht_trendmode|/ta_ht_trendmode> (Hilbert Transform - Trend vs Cycle Mode)

=head2 Group: Volume Indicators

L<ta_ad|/ta_ad> (Chaikin A/D Line), L<ta_adosc|/ta_adosc> (Chaikin A/D Oscillator), L<ta_obv|/ta_obv> (On Balance Volume)

=head2 Group: Pattern Recognition

L<ta_cdl2crows|/ta_cdl2crows> (Two Crows), L<ta_cdl3blackcrows|/ta_cdl3blackcrows> (Three Black Crows), L<ta_cdl3inside|/ta_cdl3inside> (Three Inside Up/Down), L<ta_cdl3linestrike|/ta_cdl3linestrike> (Three-Line Strike ), L<ta_cdl3outside|/ta_cdl3outside> (Three Outside Up/Down), L<ta_cdl3starsinsouth|/ta_cdl3starsinsouth> (Three Stars In The South), L<ta_cdl3whitesoldiers|/ta_cdl3whitesoldiers> (Three Advancing White Soldiers), L<ta_cdlabandonedbaby|/ta_cdlabandonedbaby> (Abandoned Baby), L<ta_cdladvanceblock|/ta_cdladvanceblock> (Advance Block), L<ta_cdlbelthold|/ta_cdlbelthold> (Belt-hold), L<ta_cdlbreakaway|/ta_cdlbreakaway> (Breakaway), L<ta_cdlclosingmarubozu|/ta_cdlclosingmarubozu> (Closing Marubozu), L<ta_cdlconcealbabyswall|/ta_cdlconcealbabyswall> (Concealing Baby Swallow), L<ta_cdlcounterattack|/ta_cdlcounterattack> (Counterattack), L<ta_cdldarkcloudcover|/ta_cdldarkcloudcover> (Dark Cloud Cover), L<ta_cdldoji|/ta_cdldoji> (Doji), L<ta_cdldojistar|/ta_cdldojistar> (Doji Star), L<ta_cdldragonflydoji|/ta_cdldragonflydoji> (Dragonfly Doji), L<ta_cdlengulfing|/ta_cdlengulfing> (Engulfing Pattern), L<ta_cdleveningdojistar|/ta_cdleveningdojistar> (Evening Doji Star), L<ta_cdleveningstar|/ta_cdleveningstar> (Evening Star), L<ta_cdlgapsidesidewhite|/ta_cdlgapsidesidewhite> (Up/Down-gap side-by-side white lines), L<ta_cdlgravestonedoji|/ta_cdlgravestonedoji> (Gravestone Doji), L<ta_cdlhammer|/ta_cdlhammer> (Hammer), L<ta_cdlhangingman|/ta_cdlhangingman> (Hanging Man), L<ta_cdlharami|/ta_cdlharami> (Harami Pattern), L<ta_cdlharamicross|/ta_cdlharamicross> (Harami Cross Pattern), L<ta_cdlhighwave|/ta_cdlhighwave> (High-Wave Candle), L<ta_cdlhikkake|/ta_cdlhikkake> (Hikkake Pattern), L<ta_cdlhikkakemod|/ta_cdlhikkakemod> (Modified Hikkake Pattern), L<ta_cdlhomingpigeon|/ta_cdlhomingpigeon> (Homing Pigeon), L<ta_cdlidentical3crows|/ta_cdlidentical3crows> (Identical Three Crows), L<ta_cdlinneck|/ta_cdlinneck> (In-Neck Pattern), L<ta_cdlinvertedhammer|/ta_cdlinvertedhammer> (Inverted Hammer), L<ta_cdlkicking|/ta_cdlkicking> (Kicking), L<ta_cdlkickingbylength|/ta_cdlkickingbylength> (Kicking - bull/bear determined by the longer marubozu), L<ta_cdlladderbottom|/ta_cdlladderbottom> (Ladder Bottom), L<ta_cdllongleggeddoji|/ta_cdllongleggeddoji> (Long Legged Doji), L<ta_cdllongline|/ta_cdllongline> (Long Line Candle), L<ta_cdlmarubozu|/ta_cdlmarubozu> (Marubozu), L<ta_cdlmatchinglow|/ta_cdlmatchinglow> (Matching Low), L<ta_cdlmathold|/ta_cdlmathold> (Mat Hold), L<ta_cdlmorningdojistar|/ta_cdlmorningdojistar> (Morning Doji Star), L<ta_cdlmorningstar|/ta_cdlmorningstar> (Morning Star), L<ta_cdlonneck|/ta_cdlonneck> (On-Neck Pattern), L<ta_cdlpiercing|/ta_cdlpiercing> (Piercing Pattern), L<ta_cdlrickshawman|/ta_cdlrickshawman> (Rickshaw Man), L<ta_cdlrisefall3methods|/ta_cdlrisefall3methods> (Rising/Falling Three Methods), L<ta_cdlseparatinglines|/ta_cdlseparatinglines> (Separating Lines), L<ta_cdlshootingstar|/ta_cdlshootingstar> (Shooting Star), L<ta_cdlshortline|/ta_cdlshortline> (Short Line Candle), L<ta_cdlspinningtop|/ta_cdlspinningtop> (Spinning Top), L<ta_cdlstalledpattern|/ta_cdlstalledpattern> (Stalled Pattern), L<ta_cdlsticksandwich|/ta_cdlsticksandwich> (Stick Sandwich), L<ta_cdltakuri|/ta_cdltakuri> (Takuri (Dragonfly Doji with very long lower shadow)), L<ta_cdltasukigap|/ta_cdltasukigap> (Tasuki Gap), L<ta_cdlthrusting|/ta_cdlthrusting> (Thrusting Pattern), L<ta_cdltristar|/ta_cdltristar> (Tristar Pattern), L<ta_cdlunique3river|/ta_cdlunique3river> (Unique 3 River), L<ta_cdlupsidegap2crows|/ta_cdlupsidegap2crows> (Upside Gap Two Crows), L<ta_cdlxsidegap3methods|/ta_cdlxsidegap3methods> (Upside/Downside Gap Three Methods)

=head2 Group: Statistic Functions

L<ta_beta|/ta_beta> (Beta), L<ta_correl|/ta_correl> (Pearson's Correlation Coefficient (r)), L<ta_linearreg|/ta_linearreg> (Linear Regression), L<ta_linearreg_angle|/ta_linearreg_angle> (Linear Regression Angle), L<ta_linearreg_intercept|/ta_linearreg_intercept> (Linear Regression Intercept), L<ta_linearreg_slope|/ta_linearreg_slope> (Linear Regression Slope), L<ta_stddev|/ta_stddev> (Standard Deviation), L<ta_tsf|/ta_tsf> (Time Series Forecast), L<ta_var|/ta_var> (Variance)

=head2 Group: Price Transform

L<ta_avgprice|/ta_avgprice> (Average Price), L<ta_medprice|/ta_medprice> (Median Price), L<ta_typprice|/ta_typprice> (Typical Price), L<ta_wclprice|/ta_wclprice> (Weighted Close Price)

=head1 HANDLING BAD VALUES

Most of the available functions may return BAD values, for example:

  use PDL;
  use PDL::Finance::TA;
  my $PD = pdl([0, 1, 2, 3, 4, 5]);
  my $MA = ta_ma($PD, 3, 1);
  print $MA;      # prints: [BAD BAD 1 2 3 4]

All available functions handles BAD values in input piddles (BAD values at the beginning are skipped), for example:

  use PDL;
  use PDL::Finance::TA;
  my $PD = pdl([0, 1, 2, 3, 4, 5]);
  my $MA1 = ta_ma($PD, 3, 1);
  say $MA1;      # prints: [BAD BAD 1 2 3 4]
  my $MA2 = ta_ma($MA1, 3, 1);
  say $MA2;      # prints: [BAD BAD BAD BAD 2 3]

=cut






=head1 FUNCTIONS



=cut






=head2 ta_bbands

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double InNbDevUp(); double InNbDevDn(); int InMAType(); double [o]outpdlUpperBand(n); double [o]outpdlMiddleBand(n); double [o]outpdlLowerBand(n))

Bollinger Bands

  ($outpdlUpperBand, $outpdlMiddleBand, $outpdlLowerBand) = ta_bbands($inpdl, $InTimePeriod, $InNbDevUp, $InNbDevDn, $InMAType);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 5
 #     valid range: min=2 max=100000
 # $InNbDevUp [Deviation multiplier for upper band] - real number
 #     default: 2
 #     valid range: min=-3e+037 max=3e+037
 # $InNbDevDn [Deviation multiplier for lower band] - real number
 #     default: 2
 #     valid range: min=-3e+037 max=3e+037
 # $InMAType [Type of Moving Average] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outpdlUpperBand - 1D piddle
 # returns: $outpdlMiddleBand - 1D piddle
 # returns: $outpdlLowerBand - 1D piddle


=for bad

ta_bbands processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_bbands = \&PDL::ta_bbands;





=head2 ta_dema

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Double Exponential Moving Average

  $outpdl = ta_dema($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_dema processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_dema = \&PDL::ta_dema;





=head2 ta_ema

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Exponential Moving Average

  $outpdl = ta_ema($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_ema processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ema = \&PDL::ta_ema;





=head2 ta_ht_trendline

=for sig

  Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Instantaneous Trendline

  $outpdl = ta_ht_trendline($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outpdl - 1D piddle


=for bad

ta_ht_trendline processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_trendline = \&PDL::ta_ht_trendline;





=head2 ta_kama

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Kaufman Adaptive Moving Average

  $outpdl = ta_kama($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_kama processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_kama = \&PDL::ta_kama;





=head2 ta_ma

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); int InMAType(); double [o]outpdl(n))

Moving average

  $outpdl = ta_ma($inpdl, $InTimePeriod, $InMAType);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=1 max=100000
 # $InMAType [Type of Moving Average] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outpdl - 1D piddle


=for bad

ta_ma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ma = \&PDL::ta_ma;





=head2 ta_mama

=for sig

  Signature: (double inpdl(n); double InFastLimit(); double InSlowLimit(); double [o]outMAMA(n); double [o]outFAMA(n))

MESA Adaptive Moving Average

  ($outMAMA, $outFAMA) = ta_mama($inpdl, $InFastLimit, $InSlowLimit);

 # $inpdl - 1D piddle with input data
 # $InFastLimit [Upper limit use in the adaptive algorithm] - real number
 #     default: 0.5
 #     valid range: min=0.01 max=0.99
 # $InSlowLimit [Lower limit use in the adaptive algorithm] - real number
 #     default: 0.05
 #     valid range: min=0.01 max=0.99
 # returns: $outMAMA - 1D piddle
 # returns: $outFAMA - 1D piddle


=for bad

ta_mama processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_mama = \&PDL::ta_mama;





=head2 ta_mavp

=for sig

  Signature: (double inpdl(n); double inPeriods(n); int InMinPeriod(); int InMaxPeriod(); int InMAType(); double [o]outpdl(n))

Moving average with variable period

  $outpdl = ta_mavp($inpdl, $inPeriods, $InMinPeriod, $InMaxPeriod, $InMAType);

 # $inpdl - 1D piddle with input data
 # $inPeriods - 1D piddle
 # $InMinPeriod [Value less than minimum will be changed to Minimum period] - integer
 #     default: 2
 #     valid range: min=2 max=100000
 # $InMaxPeriod [Value higher than maximum will be changed to Maximum period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # $InMAType [Type of Moving Average] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outpdl - 1D piddle


=for bad

ta_mavp processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_mavp = \&PDL::ta_mavp;





=head2 ta_midpoint

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

MidPoint over period

  $outpdl = ta_midpoint($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_midpoint processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_midpoint = \&PDL::ta_midpoint;





=head2 ta_midprice

=for sig

  Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Midpoint Price over period

  $outpdl = ta_midprice($high, $low, $InTimePeriod);

 # $high, $low - 1D piddles, both have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_midprice processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_midprice = \&PDL::ta_midprice;





=head2 ta_sar

=for sig

  Signature: (double high(n); double low(n); double InAcceleration(); double InMaximum(); double [o]outpdl(n))

Parabolic SAR

  $outpdl = ta_sar($high, $low, $InAcceleration, $InMaximum);

 # $high, $low - 1D piddles, both have to be the same size
 # $InAcceleration [Acceleration Factor used up to the Maximum value] - real number
 #     default: 0.02
 #     valid range: min=0 max=3e+037
 # $InMaximum [Acceleration Factor Maximum value] - real number
 #     default: 0.2
 #     valid range: min=0 max=3e+037
 # returns: $outpdl - 1D piddle


=for bad

ta_sar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_sar = \&PDL::ta_sar;





=head2 ta_sarext

=for sig

  Signature: (double high(n); double low(n); double InStartValue(); double InOffsetOnReverse(); double InAccelerationInitLong(); double InAccelerationLong(); double InAccelerationMaxLong(); double InAccelerationInitShort(); double InAccelerationShort(); double InAccelerationMaxShort(); double [o]outpdl(n))

Parabolic SAR - Extended

  $outpdl = ta_sarext($high, $low, $InStartValue, $InOffsetOnReverse, $InAccelerationInitLong, $InAccelerationLong, $InAccelerationMaxLong, $InAccelerationInitShort, $InAccelerationShort, $InAccelerationMaxShort);

 # $high, $low - 1D piddles, both have to be the same size
 # $InStartValue [Start value and direction. 0 for Auto, >0 for Long, <0 for Short] - real number
 #     default: 0
 #     valid range: min=-3e+037 max=3e+037
 # $InOffsetOnReverse [Percent offset added/removed to initial stop on short/long reversal] - real number
 #     default: 0
 #     valid range: min=0 max=3e+037
 # $InAccelerationInitLong [Acceleration Factor initial value for the Long direction] - real number
 #     default: 0.02
 #     valid range: min=0 max=3e+037
 # $InAccelerationLong [Acceleration Factor for the Long direction] - real number
 #     default: 0.02
 #     valid range: min=0 max=3e+037
 # $InAccelerationMaxLong [Acceleration Factor maximum value for the Long direction] - real number
 #     default: 0.2
 #     valid range: min=0 max=3e+037
 # $InAccelerationInitShort [Acceleration Factor initial value for the Short direction] - real number
 #     default: 0.02
 #     valid range: min=0 max=3e+037
 # $InAccelerationShort [Acceleration Factor for the Short direction] - real number
 #     default: 0.02
 #     valid range: min=0 max=3e+037
 # $InAccelerationMaxShort [Acceleration Factor maximum value for the Short direction] - real number
 #     default: 0.2
 #     valid range: min=0 max=3e+037
 # returns: $outpdl - 1D piddle


=for bad

ta_sarext processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_sarext = \&PDL::ta_sarext;





=head2 ta_sma

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Simple Moving Average

  $outpdl = ta_sma($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_sma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_sma = \&PDL::ta_sma;





=head2 ta_t3

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double InVFactor(); double [o]outpdl(n))

Triple Exponential Moving Average (T3)

  $outpdl = ta_t3($inpdl, $InTimePeriod, $InVFactor);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 5
 #     valid range: min=2 max=100000
 # $InVFactor [Volume Factor] - real number
 #     default: 0.7
 #     valid range: min=0 max=1
 # returns: $outpdl - 1D piddle


=for bad

ta_t3 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_t3 = \&PDL::ta_t3;





=head2 ta_tema

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Triple Exponential Moving Average

  $outpdl = ta_tema($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_tema processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_tema = \&PDL::ta_tema;





=head2 ta_trima

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Triangular Moving Average

  $outpdl = ta_trima($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_trima processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_trima = \&PDL::ta_trima;





=head2 ta_wma

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Weighted Moving Average

  $outpdl = ta_wma($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_wma processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_wma = \&PDL::ta_wma;





=head2 ta_atr

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average True Range

  $outpdl = ta_atr($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_atr processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_atr = \&PDL::ta_atr;





=head2 ta_natr

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Normalized Average True Range

  $outpdl = ta_natr($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_natr processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_natr = \&PDL::ta_natr;





=head2 ta_trange

=for sig

  Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

True Range

  $outpdl = ta_trange($high, $low, $close);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_trange processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_trange = \&PDL::ta_trange;





=head2 ta_adx

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average Directional Movement Index

  $outpdl = ta_adx($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_adx processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_adx = \&PDL::ta_adx;





=head2 ta_adxr

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average Directional Movement Index Rating

  $outpdl = ta_adxr($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_adxr processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_adxr = \&PDL::ta_adxr;





=head2 ta_apo

=for sig

  Signature: (double inpdl(n); int InFastPeriod(); int InSlowPeriod(); int InMAType(); double [o]outpdl(n))

Absolute Price Oscillator

  $outpdl = ta_apo($inpdl, $InFastPeriod, $InSlowPeriod, $InMAType);

 # $inpdl - 1D piddle with input data
 # $InFastPeriod [Number of period for the fast MA] - integer
 #     default: 12
 #     valid range: min=2 max=100000
 # $InSlowPeriod [Number of period for the slow MA] - integer
 #     default: 26
 #     valid range: min=2 max=100000
 # $InMAType [Type of Moving Average] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outpdl - 1D piddle


=for bad

ta_apo processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_apo = \&PDL::ta_apo;





=head2 ta_aroon

=for sig

  Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outAroonDown(n); double [o]outAroonUp(n))

Aroon

  ($outAroonDown, $outAroonUp) = ta_aroon($high, $low, $InTimePeriod);

 # $high, $low - 1D piddles, both have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outAroonDown - 1D piddle
 # returns: $outAroonUp - 1D piddle


=for bad

ta_aroon processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_aroon = \&PDL::ta_aroon;





=head2 ta_aroonosc

=for sig

  Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Aroon Oscillator

  $outpdl = ta_aroonosc($high, $low, $InTimePeriod);

 # $high, $low - 1D piddles, both have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_aroonosc processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_aroonosc = \&PDL::ta_aroonosc;





=head2 ta_bop

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double [o]outpdl(n))

Balance Of Power

  $outpdl = ta_bop($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_bop processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_bop = \&PDL::ta_bop;





=head2 ta_cci

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Commodity Channel Index

  $outpdl = ta_cci($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_cci processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cci = \&PDL::ta_cci;





=head2 ta_cmo

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Chande Momentum Oscillator

  $outpdl = ta_cmo($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_cmo processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cmo = \&PDL::ta_cmo;





=head2 ta_dx

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Directional Movement Index

  $outpdl = ta_dx($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_dx processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_dx = \&PDL::ta_dx;





=head2 ta_macd

=for sig

  Signature: (double inpdl(n); int InFastPeriod(); int InSlowPeriod(); int InSignalPeriod(); double [o]outMACD(n); double [o]outMACDSignal(n); double [o]outMACDHist(n))

Moving Average Convergence/Divergence

  ($outMACD, $outMACDSignal, $outMACDHist) = ta_macd($inpdl, $InFastPeriod, $InSlowPeriod, $InSignalPeriod);

 # $inpdl - 1D piddle with input data
 # $InFastPeriod [Number of period for the fast MA] - integer
 #     default: 12
 #     valid range: min=2 max=100000
 # $InSlowPeriod [Number of period for the slow MA] - integer
 #     default: 26
 #     valid range: min=2 max=100000
 # $InSignalPeriod [Smoothing for the signal line (nb of period)] - integer
 #     default: 9
 #     valid range: min=1 max=100000
 # returns: $outMACD - 1D piddle
 # returns: $outMACDSignal - 1D piddle
 # returns: $outMACDHist - 1D piddle


=for bad

ta_macd processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_macd = \&PDL::ta_macd;





=head2 ta_macdext

=for sig

  Signature: (double inpdl(n); int InFastPeriod(); int InFastMAType(); int InSlowPeriod(); int InSlowMAType(); int InSignalPeriod(); int InSignalMAType(); double [o]outMACD(n); double [o]outMACDSignal(n); double [o]outMACDHist(n))

MACD with controllable MA type

  ($outMACD, $outMACDSignal, $outMACDHist) = ta_macdext($inpdl, $InFastPeriod, $InFastMAType, $InSlowPeriod, $InSlowMAType, $InSignalPeriod, $InSignalMAType);

 # $inpdl - 1D piddle with input data
 # $InFastPeriod [Number of period for the fast MA] - integer
 #     default: 12
 #     valid range: min=2 max=100000
 # $InFastMAType [Type of Moving Average for fast MA] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # $InSlowPeriod [Number of period for the slow MA] - integer
 #     default: 26
 #     valid range: min=2 max=100000
 # $InSlowMAType [Type of Moving Average for slow MA] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # $InSignalPeriod [Smoothing for the signal line (nb of period)] - integer
 #     default: 9
 #     valid range: min=1 max=100000
 # $InSignalMAType [Type of Moving Average for signal line] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outMACD - 1D piddle
 # returns: $outMACDSignal - 1D piddle
 # returns: $outMACDHist - 1D piddle


=for bad

ta_macdext processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_macdext = \&PDL::ta_macdext;





=head2 ta_macdfix

=for sig

  Signature: (double inpdl(n); int InSignalPeriod(); double [o]outMACD(n); double [o]outMACDSignal(n); double [o]outMACDHist(n))

Moving Average Convergence/Divergence Fix 12/26

  ($outMACD, $outMACDSignal, $outMACDHist) = ta_macdfix($inpdl, $InSignalPeriod);

 # $inpdl - 1D piddle with input data
 # $InSignalPeriod [Smoothing for the signal line (nb of period)] - integer
 #     default: 9
 #     valid range: min=1 max=100000
 # returns: $outMACD - 1D piddle
 # returns: $outMACDSignal - 1D piddle
 # returns: $outMACDHist - 1D piddle


=for bad

ta_macdfix processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_macdfix = \&PDL::ta_macdfix;





=head2 ta_mfi

=for sig

  Signature: (double high(n); double low(n); double close(n); double volume(n); int InTimePeriod(); double [o]outpdl(n))

Money Flow Index

  $outpdl = ta_mfi($high, $low, $close, $volume, $InTimePeriod);

 # $high, $low, $close, $volume - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_mfi processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_mfi = \&PDL::ta_mfi;





=head2 ta_minus_di

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Minus Directional Indicator

  $outpdl = ta_minus_di($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_minus_di processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_minus_di = \&PDL::ta_minus_di;





=head2 ta_minus_dm

=for sig

  Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Minus Directional Movement

  $outpdl = ta_minus_dm($high, $low, $InTimePeriod);

 # $high, $low - 1D piddles, both have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_minus_dm processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_minus_dm = \&PDL::ta_minus_dm;





=head2 ta_mom

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Momentum

  $outpdl = ta_mom($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 10
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_mom processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_mom = \&PDL::ta_mom;





=head2 ta_plus_di

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Plus Directional Indicator

  $outpdl = ta_plus_di($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_plus_di processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_plus_di = \&PDL::ta_plus_di;





=head2 ta_plus_dm

=for sig

  Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Plus Directional Movement

  $outpdl = ta_plus_dm($high, $low, $InTimePeriod);

 # $high, $low - 1D piddles, both have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_plus_dm processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_plus_dm = \&PDL::ta_plus_dm;





=head2 ta_ppo

=for sig

  Signature: (double inpdl(n); int InFastPeriod(); int InSlowPeriod(); int InMAType(); double [o]outpdl(n))

Percentage Price Oscillator

  $outpdl = ta_ppo($inpdl, $InFastPeriod, $InSlowPeriod, $InMAType);

 # $inpdl - 1D piddle with input data
 # $InFastPeriod [Number of period for the fast MA] - integer
 #     default: 12
 #     valid range: min=2 max=100000
 # $InSlowPeriod [Number of period for the slow MA] - integer
 #     default: 26
 #     valid range: min=2 max=100000
 # $InMAType [Type of Moving Average] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outpdl - 1D piddle


=for bad

ta_ppo processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ppo = \&PDL::ta_ppo;





=head2 ta_roc

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change : ((price/prevPrice-1)*100)

  $outpdl = ta_roc($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 10
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_roc processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_roc = \&PDL::ta_roc;





=head2 ta_rocp

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change Percentage: (price-prevPrice/prevPrice)

  $outpdl = ta_rocp($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 10
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_rocp processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_rocp = \&PDL::ta_rocp;





=head2 ta_rocr

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change ratio: (price/prevPrice)

  $outpdl = ta_rocr($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 10
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_rocr processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_rocr = \&PDL::ta_rocr;





=head2 ta_rocr100

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change ratio 100 scale: (price/prevPrice*100)

  $outpdl = ta_rocr100($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 10
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_rocr100 processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_rocr100 = \&PDL::ta_rocr100;





=head2 ta_rsi

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Relative Strength Index

  $outpdl = ta_rsi($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_rsi processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_rsi = \&PDL::ta_rsi;





=head2 ta_stoch

=for sig

  Signature: (double high(n); double low(n); double close(n); int InFastK_Period(); int InSlowK_Period(); int InSlowK_MAType(); int InSlowD_Period(); int InSlowD_MAType(); double [o]outSlowK(n); double [o]outSlowD(n))

Stochastic

  ($outSlowK, $outSlowD) = ta_stoch($high, $low, $close, $InFastK_Period, $InSlowK_Period, $InSlowK_MAType, $InSlowD_Period, $InSlowD_MAType);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InFastK_Period [Time period for building the Fast-K line] - integer
 #     default: 5
 #     valid range: min=1 max=100000
 # $InSlowK_Period [Smoothing for making the Slow-K line. Usually set to 3] - integer
 #     default: 3
 #     valid range: min=1 max=100000
 # $InSlowK_MAType [Type of Moving Average for Slow-K] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # $InSlowD_Period [Smoothing for making the Slow-D line] - integer
 #     default: 3
 #     valid range: min=1 max=100000
 # $InSlowD_MAType [Type of Moving Average for Slow-D] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outSlowK - 1D piddle
 # returns: $outSlowD - 1D piddle


=for bad

ta_stoch processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_stoch = \&PDL::ta_stoch;





=head2 ta_stochf

=for sig

  Signature: (double high(n); double low(n); double close(n); int InFastK_Period(); int InFastD_Period(); int InFastD_MAType(); double [o]outFastK(n); double [o]outFastD(n))

Stochastic Fast

  ($outFastK, $outFastD) = ta_stochf($high, $low, $close, $InFastK_Period, $InFastD_Period, $InFastD_MAType);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InFastK_Period [Time period for building the Fast-K line] - integer
 #     default: 5
 #     valid range: min=1 max=100000
 # $InFastD_Period [Smoothing for making the Fast-D line. Usually set to 3] - integer
 #     default: 3
 #     valid range: min=1 max=100000
 # $InFastD_MAType [Type of Moving Average for Fast-D] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outFastK - 1D piddle
 # returns: $outFastD - 1D piddle


=for bad

ta_stochf processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_stochf = \&PDL::ta_stochf;





=head2 ta_stochrsi

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); int InFastK_Period(); int InFastD_Period(); int InFastD_MAType(); double [o]outFastK(n); double [o]outFastD(n))

Stochastic Relative Strength Index

  ($outFastK, $outFastD) = ta_stochrsi($inpdl, $InTimePeriod, $InFastK_Period, $InFastD_Period, $InFastD_MAType);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # $InFastK_Period [Time period for building the Fast-K line] - integer
 #     default: 5
 #     valid range: min=1 max=100000
 # $InFastD_Period [Smoothing for making the Fast-D line. Usually set to 3] - integer
 #     default: 3
 #     valid range: min=1 max=100000
 # $InFastD_MAType [Type of Moving Average for Fast-D] - integer
 #     default: 0
 #     valid values: 0=SMA 1=EMA 2=WMA 3=DEMA 4=TEMA 5=TRIMA 6=KAMA 7=MAMA 8=T3
 # returns: $outFastK - 1D piddle
 # returns: $outFastD - 1D piddle


=for bad

ta_stochrsi processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_stochrsi = \&PDL::ta_stochrsi;





=head2 ta_trix

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

1-day Rate-Of-Change (ROC of a Triple Smooth EMA)

  $outpdl = ta_trix($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_trix processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_trix = \&PDL::ta_trix;





=head2 ta_ultosc

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod1(); int InTimePeriod2(); int InTimePeriod3(); double [o]outpdl(n))

Ultimate Oscillator

  $outpdl = ta_ultosc($high, $low, $close, $InTimePeriod1, $InTimePeriod2, $InTimePeriod3);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod1 [Number of bars for 1st period.] - integer
 #     default: 7
 #     valid range: min=1 max=100000
 # $InTimePeriod2 [Number of bars fro 2nd period] - integer
 #     default: 14
 #     valid range: min=1 max=100000
 # $InTimePeriod3 [Number of bars for 3rd period] - integer
 #     default: 28
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_ultosc processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ultosc = \&PDL::ta_ultosc;





=head2 ta_willr

=for sig

  Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Williams' %R

  $outpdl = ta_willr($high, $low, $close, $InTimePeriod);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_willr processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_willr = \&PDL::ta_willr;





=head2 ta_ht_dcperiod

=for sig

  Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Dominant Cycle Period

  $outpdl = ta_ht_dcperiod($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outpdl - 1D piddle


=for bad

ta_ht_dcperiod processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_dcperiod = \&PDL::ta_ht_dcperiod;





=head2 ta_ht_dcphase

=for sig

  Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Dominant Cycle Phase

  $outpdl = ta_ht_dcphase($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outpdl - 1D piddle


=for bad

ta_ht_dcphase processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_dcphase = \&PDL::ta_ht_dcphase;





=head2 ta_ht_phasor

=for sig

  Signature: (double inpdl(n); double [o]outInPhase(n); double [o]outQuadrature(n))

Hilbert Transform - Phasor Components

  ($outInPhase, $outQuadrature) = ta_ht_phasor($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outInPhase - 1D piddle
 # returns: $outQuadrature - 1D piddle


=for bad

ta_ht_phasor processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_phasor = \&PDL::ta_ht_phasor;





=head2 ta_ht_sine

=for sig

  Signature: (double inpdl(n); double [o]outSine(n); double [o]outLeadSine(n))

Hilbert Transform - SineWave

  ($outSine, $outLeadSine) = ta_ht_sine($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outSine - 1D piddle
 # returns: $outLeadSine - 1D piddle


=for bad

ta_ht_sine processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_sine = \&PDL::ta_ht_sine;





=head2 ta_ht_trendmode

=for sig

  Signature: (double inpdl(n); int [o]outInteger(n))

Hilbert Transform - Trend vs Cycle Mode

  $outInteger = ta_ht_trendmode($inpdl);

 # $inpdl - 1D piddle with input data
 # returns: $outInteger - 1D piddle


=for bad

ta_ht_trendmode processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ht_trendmode = \&PDL::ta_ht_trendmode;





=head2 ta_ad

=for sig

  Signature: (double high(n); double low(n); double close(n); double volume(n); double [o]outpdl(n))

Chaikin A/D Line

  $outpdl = ta_ad($high, $low, $close, $volume);

 # $high, $low, $close, $volume - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_ad processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_ad = \&PDL::ta_ad;





=head2 ta_adosc

=for sig

  Signature: (double high(n); double low(n); double close(n); double volume(n); int InFastPeriod(); int InSlowPeriod(); double [o]outpdl(n))

Chaikin A/D Oscillator

  $outpdl = ta_adosc($high, $low, $close, $volume, $InFastPeriod, $InSlowPeriod);

 # $high, $low, $close, $volume - 1D piddles, all have to be the same size
 # $InFastPeriod [Number of period for the fast MA] - integer
 #     default: 3
 #     valid range: min=2 max=100000
 # $InSlowPeriod [Number of period for the slow MA] - integer
 #     default: 10
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_adosc processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_adosc = \&PDL::ta_adosc;





=head2 ta_obv

=for sig

  Signature: (double inpdl(n); double volume(n); double [o]outpdl(n))

On Balance Volume

  $outpdl = ta_obv($inpdl, $volume);

 # $inpdl - 1D piddle with input data
 # $volume - 1D piddle
 # returns: $outpdl - 1D piddle


=for bad

ta_obv processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_obv = \&PDL::ta_obv;





=head2 ta_cdl2crows

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Two Crows

  $outInteger = ta_cdl2crows($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl2crows processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl2crows = \&PDL::ta_cdl2crows;





=head2 ta_cdl3blackcrows

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Black Crows

  $outInteger = ta_cdl3blackcrows($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3blackcrows processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3blackcrows = \&PDL::ta_cdl3blackcrows;





=head2 ta_cdl3inside

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Inside Up/Down

  $outInteger = ta_cdl3inside($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3inside processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3inside = \&PDL::ta_cdl3inside;





=head2 ta_cdl3linestrike

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three-Line Strike

  $outInteger = ta_cdl3linestrike($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3linestrike processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3linestrike = \&PDL::ta_cdl3linestrike;





=head2 ta_cdl3outside

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Outside Up/Down

  $outInteger = ta_cdl3outside($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3outside processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3outside = \&PDL::ta_cdl3outside;





=head2 ta_cdl3starsinsouth

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Stars In The South

  $outInteger = ta_cdl3starsinsouth($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3starsinsouth processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3starsinsouth = \&PDL::ta_cdl3starsinsouth;





=head2 ta_cdl3whitesoldiers

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Advancing White Soldiers

  $outInteger = ta_cdl3whitesoldiers($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdl3whitesoldiers processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdl3whitesoldiers = \&PDL::ta_cdl3whitesoldiers;





=head2 ta_cdlabandonedbaby

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Abandoned Baby

  $outInteger = ta_cdlabandonedbaby($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.3
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlabandonedbaby processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlabandonedbaby = \&PDL::ta_cdlabandonedbaby;





=head2 ta_cdladvanceblock

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Advance Block

  $outInteger = ta_cdladvanceblock($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdladvanceblock processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdladvanceblock = \&PDL::ta_cdladvanceblock;





=head2 ta_cdlbelthold

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Belt-hold

  $outInteger = ta_cdlbelthold($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlbelthold processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlbelthold = \&PDL::ta_cdlbelthold;





=head2 ta_cdlbreakaway

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Breakaway

  $outInteger = ta_cdlbreakaway($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlbreakaway processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlbreakaway = \&PDL::ta_cdlbreakaway;





=head2 ta_cdlclosingmarubozu

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Closing Marubozu

  $outInteger = ta_cdlclosingmarubozu($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlclosingmarubozu processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlclosingmarubozu = \&PDL::ta_cdlclosingmarubozu;





=head2 ta_cdlconcealbabyswall

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Concealing Baby Swallow

  $outInteger = ta_cdlconcealbabyswall($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlconcealbabyswall processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlconcealbabyswall = \&PDL::ta_cdlconcealbabyswall;





=head2 ta_cdlcounterattack

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Counterattack

  $outInteger = ta_cdlcounterattack($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlcounterattack processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlcounterattack = \&PDL::ta_cdlcounterattack;





=head2 ta_cdldarkcloudcover

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Dark Cloud Cover

  $outInteger = ta_cdldarkcloudcover($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.5
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdldarkcloudcover processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdldarkcloudcover = \&PDL::ta_cdldarkcloudcover;





=head2 ta_cdldoji

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Doji

  $outInteger = ta_cdldoji($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdldoji processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdldoji = \&PDL::ta_cdldoji;





=head2 ta_cdldojistar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Doji Star

  $outInteger = ta_cdldojistar($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdldojistar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdldojistar = \&PDL::ta_cdldojistar;





=head2 ta_cdldragonflydoji

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Dragonfly Doji

  $outInteger = ta_cdldragonflydoji($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdldragonflydoji processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdldragonflydoji = \&PDL::ta_cdldragonflydoji;





=head2 ta_cdlengulfing

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Engulfing Pattern

  $outInteger = ta_cdlengulfing($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlengulfing processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlengulfing = \&PDL::ta_cdlengulfing;





=head2 ta_cdleveningdojistar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Evening Doji Star

  $outInteger = ta_cdleveningdojistar($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.3
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdleveningdojistar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdleveningdojistar = \&PDL::ta_cdleveningdojistar;





=head2 ta_cdleveningstar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Evening Star

  $outInteger = ta_cdleveningstar($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.3
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdleveningstar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdleveningstar = \&PDL::ta_cdleveningstar;





=head2 ta_cdlgapsidesidewhite

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Up/Down-gap side-by-side white lines

  $outInteger = ta_cdlgapsidesidewhite($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlgapsidesidewhite processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlgapsidesidewhite = \&PDL::ta_cdlgapsidesidewhite;





=head2 ta_cdlgravestonedoji

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Gravestone Doji

  $outInteger = ta_cdlgravestonedoji($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlgravestonedoji processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlgravestonedoji = \&PDL::ta_cdlgravestonedoji;





=head2 ta_cdlhammer

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hammer

  $outInteger = ta_cdlhammer($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhammer processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhammer = \&PDL::ta_cdlhammer;





=head2 ta_cdlhangingman

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hanging Man

  $outInteger = ta_cdlhangingman($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhangingman processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhangingman = \&PDL::ta_cdlhangingman;





=head2 ta_cdlharami

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Harami Pattern

  $outInteger = ta_cdlharami($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlharami processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlharami = \&PDL::ta_cdlharami;





=head2 ta_cdlharamicross

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Harami Cross Pattern

  $outInteger = ta_cdlharamicross($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlharamicross processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlharamicross = \&PDL::ta_cdlharamicross;





=head2 ta_cdlhighwave

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

High-Wave Candle

  $outInteger = ta_cdlhighwave($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhighwave processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhighwave = \&PDL::ta_cdlhighwave;





=head2 ta_cdlhikkake

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hikkake Pattern

  $outInteger = ta_cdlhikkake($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhikkake processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhikkake = \&PDL::ta_cdlhikkake;





=head2 ta_cdlhikkakemod

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Modified Hikkake Pattern

  $outInteger = ta_cdlhikkakemod($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhikkakemod processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhikkakemod = \&PDL::ta_cdlhikkakemod;





=head2 ta_cdlhomingpigeon

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Homing Pigeon

  $outInteger = ta_cdlhomingpigeon($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlhomingpigeon processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlhomingpigeon = \&PDL::ta_cdlhomingpigeon;





=head2 ta_cdlidentical3crows

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Identical Three Crows

  $outInteger = ta_cdlidentical3crows($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlidentical3crows processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlidentical3crows = \&PDL::ta_cdlidentical3crows;





=head2 ta_cdlinneck

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

In-Neck Pattern

  $outInteger = ta_cdlinneck($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlinneck processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlinneck = \&PDL::ta_cdlinneck;





=head2 ta_cdlinvertedhammer

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Inverted Hammer

  $outInteger = ta_cdlinvertedhammer($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlinvertedhammer processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlinvertedhammer = \&PDL::ta_cdlinvertedhammer;





=head2 ta_cdlkicking

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Kicking

  $outInteger = ta_cdlkicking($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlkicking processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlkicking = \&PDL::ta_cdlkicking;





=head2 ta_cdlkickingbylength

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Kicking - bull/bear determined by the longer marubozu

  $outInteger = ta_cdlkickingbylength($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlkickingbylength processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlkickingbylength = \&PDL::ta_cdlkickingbylength;





=head2 ta_cdlladderbottom

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Ladder Bottom

  $outInteger = ta_cdlladderbottom($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlladderbottom processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlladderbottom = \&PDL::ta_cdlladderbottom;





=head2 ta_cdllongleggeddoji

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Long Legged Doji

  $outInteger = ta_cdllongleggeddoji($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdllongleggeddoji processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdllongleggeddoji = \&PDL::ta_cdllongleggeddoji;





=head2 ta_cdllongline

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Long Line Candle

  $outInteger = ta_cdllongline($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdllongline processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdllongline = \&PDL::ta_cdllongline;





=head2 ta_cdlmarubozu

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Marubozu

  $outInteger = ta_cdlmarubozu($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlmarubozu processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlmarubozu = \&PDL::ta_cdlmarubozu;





=head2 ta_cdlmatchinglow

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Matching Low

  $outInteger = ta_cdlmatchinglow($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlmatchinglow processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlmatchinglow = \&PDL::ta_cdlmatchinglow;





=head2 ta_cdlmathold

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Mat Hold

  $outInteger = ta_cdlmathold($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.5
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlmathold processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlmathold = \&PDL::ta_cdlmathold;





=head2 ta_cdlmorningdojistar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Morning Doji Star

  $outInteger = ta_cdlmorningdojistar($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.3
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlmorningdojistar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlmorningdojistar = \&PDL::ta_cdlmorningdojistar;





=head2 ta_cdlmorningstar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Morning Star

  $outInteger = ta_cdlmorningstar($open, $high, $low, $close, $InPenetration);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # $InPenetration [Percentage of penetration of a candle within another candle] - real number
 #     default: 0.3
 #     valid range: min=0 max=3e+037
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlmorningstar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlmorningstar = \&PDL::ta_cdlmorningstar;





=head2 ta_cdlonneck

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

On-Neck Pattern

  $outInteger = ta_cdlonneck($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlonneck processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlonneck = \&PDL::ta_cdlonneck;





=head2 ta_cdlpiercing

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Piercing Pattern

  $outInteger = ta_cdlpiercing($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlpiercing processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlpiercing = \&PDL::ta_cdlpiercing;





=head2 ta_cdlrickshawman

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Rickshaw Man

  $outInteger = ta_cdlrickshawman($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlrickshawman processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlrickshawman = \&PDL::ta_cdlrickshawman;





=head2 ta_cdlrisefall3methods

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Rising/Falling Three Methods

  $outInteger = ta_cdlrisefall3methods($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlrisefall3methods processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlrisefall3methods = \&PDL::ta_cdlrisefall3methods;





=head2 ta_cdlseparatinglines

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Separating Lines

  $outInteger = ta_cdlseparatinglines($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlseparatinglines processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlseparatinglines = \&PDL::ta_cdlseparatinglines;





=head2 ta_cdlshootingstar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Shooting Star

  $outInteger = ta_cdlshootingstar($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlshootingstar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlshootingstar = \&PDL::ta_cdlshootingstar;





=head2 ta_cdlshortline

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Short Line Candle

  $outInteger = ta_cdlshortline($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlshortline processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlshortline = \&PDL::ta_cdlshortline;





=head2 ta_cdlspinningtop

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Spinning Top

  $outInteger = ta_cdlspinningtop($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlspinningtop processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlspinningtop = \&PDL::ta_cdlspinningtop;





=head2 ta_cdlstalledpattern

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Stalled Pattern

  $outInteger = ta_cdlstalledpattern($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlstalledpattern processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlstalledpattern = \&PDL::ta_cdlstalledpattern;





=head2 ta_cdlsticksandwich

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Stick Sandwich

  $outInteger = ta_cdlsticksandwich($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlsticksandwich processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlsticksandwich = \&PDL::ta_cdlsticksandwich;





=head2 ta_cdltakuri

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Takuri (Dragonfly Doji with very long lower shadow)

  $outInteger = ta_cdltakuri($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdltakuri processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdltakuri = \&PDL::ta_cdltakuri;





=head2 ta_cdltasukigap

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Tasuki Gap

  $outInteger = ta_cdltasukigap($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdltasukigap processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdltasukigap = \&PDL::ta_cdltasukigap;





=head2 ta_cdlthrusting

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Thrusting Pattern

  $outInteger = ta_cdlthrusting($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlthrusting processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlthrusting = \&PDL::ta_cdlthrusting;





=head2 ta_cdltristar

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Tristar Pattern

  $outInteger = ta_cdltristar($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdltristar processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdltristar = \&PDL::ta_cdltristar;





=head2 ta_cdlunique3river

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Unique 3 River

  $outInteger = ta_cdlunique3river($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlunique3river processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlunique3river = \&PDL::ta_cdlunique3river;





=head2 ta_cdlupsidegap2crows

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Upside Gap Two Crows

  $outInteger = ta_cdlupsidegap2crows($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlupsidegap2crows processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlupsidegap2crows = \&PDL::ta_cdlupsidegap2crows;





=head2 ta_cdlxsidegap3methods

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Upside/Downside Gap Three Methods

  $outInteger = ta_cdlxsidegap3methods($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outInteger - 1D piddle


=for bad

ta_cdlxsidegap3methods processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_cdlxsidegap3methods = \&PDL::ta_cdlxsidegap3methods;





=head2 ta_beta

=for sig

  Signature: (double inpdl0(n); double inpdl1(n); int InTimePeriod(); double [o]outpdl(n))

Beta

  $outpdl = ta_beta($inpdl0, $inpdl1, $InTimePeriod);

 # $inpdl0 - 1D piddle
 # $inpdl1 - 1D piddle
 # $InTimePeriod [Number of period] - integer
 #     default: 5
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_beta processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_beta = \&PDL::ta_beta;





=head2 ta_correl

=for sig

  Signature: (double inpdl0(n); double inpdl1(n); int InTimePeriod(); double [o]outpdl(n))

Pearson's Correlation Coefficient (r)

  $outpdl = ta_correl($inpdl0, $inpdl1, $InTimePeriod);

 # $inpdl0 - 1D piddle
 # $inpdl1 - 1D piddle
 # $InTimePeriod [Number of period] - integer
 #     default: 30
 #     valid range: min=1 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_correl processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_correl = \&PDL::ta_correl;





=head2 ta_linearreg

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression

  $outpdl = ta_linearreg($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_linearreg processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_linearreg = \&PDL::ta_linearreg;





=head2 ta_linearreg_angle

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Angle

  $outpdl = ta_linearreg_angle($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_linearreg_angle processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_linearreg_angle = \&PDL::ta_linearreg_angle;





=head2 ta_linearreg_intercept

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Intercept

  $outpdl = ta_linearreg_intercept($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_linearreg_intercept processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_linearreg_intercept = \&PDL::ta_linearreg_intercept;





=head2 ta_linearreg_slope

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Slope

  $outpdl = ta_linearreg_slope($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_linearreg_slope processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_linearreg_slope = \&PDL::ta_linearreg_slope;





=head2 ta_stddev

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double InNbDev(); double [o]outpdl(n))

Standard Deviation

  $outpdl = ta_stddev($inpdl, $InTimePeriod, $InNbDev);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 5
 #     valid range: min=2 max=100000
 # $InNbDev [Nb of deviations] - real number
 #     default: 1
 #     valid range: min=-3e+037 max=3e+037
 # returns: $outpdl - 1D piddle


=for bad

ta_stddev processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_stddev = \&PDL::ta_stddev;





=head2 ta_tsf

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Time Series Forecast

  $outpdl = ta_tsf($inpdl, $InTimePeriod);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 14
 #     valid range: min=2 max=100000
 # returns: $outpdl - 1D piddle


=for bad

ta_tsf processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_tsf = \&PDL::ta_tsf;





=head2 ta_var

=for sig

  Signature: (double inpdl(n); int InTimePeriod(); double InNbDev(); double [o]outpdl(n))

Variance

  $outpdl = ta_var($inpdl, $InTimePeriod, $InNbDev);

 # $inpdl - 1D piddle with input data
 # $InTimePeriod [Number of period] - integer
 #     default: 5
 #     valid range: min=1 max=100000
 # $InNbDev [Nb of deviations] - real number
 #     default: 1
 #     valid range: min=-3e+037 max=3e+037
 # returns: $outpdl - 1D piddle


=for bad

ta_var processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_var = \&PDL::ta_var;





=head2 ta_avgprice

=for sig

  Signature: (double open(n); double high(n); double low(n); double close(n); double [o]outpdl(n))

Average Price

  $outpdl = ta_avgprice($open, $high, $low, $close);

 # $open, $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_avgprice processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_avgprice = \&PDL::ta_avgprice;





=head2 ta_medprice

=for sig

  Signature: (double high(n); double low(n); double [o]outpdl(n))

Median Price

  $outpdl = ta_medprice($high, $low);

 # $high, $low - 1D piddles, both have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_medprice processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_medprice = \&PDL::ta_medprice;





=head2 ta_typprice

=for sig

  Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

Typical Price

  $outpdl = ta_typprice($high, $low, $close);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_typprice processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_typprice = \&PDL::ta_typprice;





=head2 ta_wclprice

=for sig

  Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

Weighted Close Price

  $outpdl = ta_wclprice($high, $low, $close);

 # $high, $low, $close - 1D piddles, all have to be the same size
 # returns: $outpdl - 1D piddle


=for bad

ta_wclprice processes bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ta_wclprice = \&PDL::ta_wclprice;



;

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut




# Exit with OK status

1;

		   