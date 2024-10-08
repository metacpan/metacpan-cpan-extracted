# NAME

PDL::Finance::TA - Technical Analysis Library (http://ta-lib.org) bindings for PDL

# SYNOPSIS

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

# DESCRIPTION

TA-Lib library - [http://ta-lib.org](http://ta-lib.org) - is a multi-platform tool for market analysis. TA-Lib is widely used by trading
software developers requiring to perform technical analysis of financial market data.

This module provides an [PDL](https://metacpan.org/pod/PDL) interface for TA-Lib library. It combines rich TA-Lib functionality with excellent
[PDL](https://metacpan.org/pod/PDL) performance of handling huge data.

If you are not a [PDL](https://metacpan.org/pod/PDL) user you might be interested in [Finance::TA](https://metacpan.org/pod/Finance%3A%3ATA) module which provides approximately
the same set of functions working with common perl data structures (which is fine if you are not about to process large
data sets and if you generally do not worry about performace).

# FUNCTION INDEX

## Group: Overlap Studies

[ta\_bbands](#ta_bbands) (Bollinger Bands), [ta\_dema](#ta_dema) (Double Exponential Moving Average), [ta\_ema](#ta_ema) (Exponential Moving Average), [ta\_ht\_trendline](#ta_ht_trendline) (Hilbert Transform - Instantaneous Trendline), [ta\_kama](#ta_kama) (Kaufman Adaptive Moving Average), [ta\_ma](#ta_ma) (Moving average), [ta\_mama](#ta_mama) (MESA Adaptive Moving Average), [ta\_mavp](#ta_mavp) (Moving average with variable period), [ta\_midpoint](#ta_midpoint) (MidPoint over period), [ta\_midprice](#ta_midprice) (Midpoint Price over period), [ta\_sar](#ta_sar) (Parabolic SAR), [ta\_sarext](#ta_sarext) (Parabolic SAR - Extended), [ta\_sma](#ta_sma) (Simple Moving Average), [ta\_t3](#ta_t3) (Triple Exponential Moving Average (T3)), [ta\_tema](#ta_tema) (Triple Exponential Moving Average), [ta\_trima](#ta_trima) (Triangular Moving Average), [ta\_wma](#ta_wma) (Weighted Moving Average)

## Group: Volatility Indicators

[ta\_atr](#ta_atr) (Average True Range), [ta\_natr](#ta_natr) (Normalized Average True Range), [ta\_trange](#ta_trange) (True Range)

## Group: Momentum Indicators

[ta\_adx](#ta_adx) (Average Directional Movement Index), [ta\_adxr](#ta_adxr) (Average Directional Movement Index Rating), [ta\_apo](#ta_apo) (Absolute Price Oscillator), [ta\_aroon](#ta_aroon) (Aroon), [ta\_aroonosc](#ta_aroonosc) (Aroon Oscillator), [ta\_bop](#ta_bop) (Balance Of Power), [ta\_cci](#ta_cci) (Commodity Channel Index), [ta\_cmo](#ta_cmo) (Chande Momentum Oscillator), [ta\_dx](#ta_dx) (Directional Movement Index), [ta\_macd](#ta_macd) (Moving Average Convergence/Divergence), [ta\_macdext](#ta_macdext) (MACD with controllable MA type), [ta\_macdfix](#ta_macdfix) (Moving Average Convergence/Divergence Fix 12/26), [ta\_mfi](#ta_mfi) (Money Flow Index), [ta\_minus\_di](#ta_minus_di) (Minus Directional Indicator), [ta\_minus\_dm](#ta_minus_dm) (Minus Directional Movement), [ta\_mom](#ta_mom) (Momentum), [ta\_plus\_di](#ta_plus_di) (Plus Directional Indicator), [ta\_plus\_dm](#ta_plus_dm) (Plus Directional Movement), [ta\_ppo](#ta_ppo) (Percentage Price Oscillator), [ta\_roc](#ta_roc) (Rate of change : ((price/prevPrice)-1)\*100), [ta\_rocp](#ta_rocp) (Rate of change Percentage: (price-prevPrice)/prevPrice), [ta\_rocr](#ta_rocr) (Rate of change ratio: (price/prevPrice)), [ta\_rocr100](#ta_rocr100) (Rate of change ratio 100 scale: (price/prevPrice)\*100), [ta\_rsi](#ta_rsi) (Relative Strength Index), [ta\_stoch](#ta_stoch) (Stochastic), [ta\_stochf](#ta_stochf) (Stochastic Fast), [ta\_stochrsi](#ta_stochrsi) (Stochastic Relative Strength Index), [ta\_trix](#ta_trix) (1-day Rate-Of-Change (ROC) of a Triple Smooth EMA), [ta\_ultosc](#ta_ultosc) (Ultimate Oscillator), [ta\_willr](#ta_willr) (Williams' %R)

## Group: Cycle Indicators

[ta\_ht\_dcperiod](#ta_ht_dcperiod) (Hilbert Transform - Dominant Cycle Period), [ta\_ht\_dcphase](#ta_ht_dcphase) (Hilbert Transform - Dominant Cycle Phase), [ta\_ht\_phasor](#ta_ht_phasor) (Hilbert Transform - Phasor Components), [ta\_ht\_sine](#ta_ht_sine) (Hilbert Transform - SineWave), [ta\_ht\_trendmode](#ta_ht_trendmode) (Hilbert Transform - Trend vs Cycle Mode)

## Group: Volume Indicators

[ta\_ad](#ta_ad) (Chaikin A/D Line), [ta\_adosc](#ta_adosc) (Chaikin A/D Oscillator), [ta\_obv](#ta_obv) (On Balance Volume)

## Group: Pattern Recognition

[ta\_cdl2crows](#ta_cdl2crows) (Two Crows), [ta\_cdl3blackcrows](#ta_cdl3blackcrows) (Three Black Crows), [ta\_cdl3inside](#ta_cdl3inside) (Three Inside Up/Down), [ta\_cdl3linestrike](#ta_cdl3linestrike) (Three-Line Strike ), [ta\_cdl3outside](#ta_cdl3outside) (Three Outside Up/Down), [ta\_cdl3starsinsouth](#ta_cdl3starsinsouth) (Three Stars In The South), [ta\_cdl3whitesoldiers](#ta_cdl3whitesoldiers) (Three Advancing White Soldiers), [ta\_cdlabandonedbaby](#ta_cdlabandonedbaby) (Abandoned Baby), [ta\_cdladvanceblock](#ta_cdladvanceblock) (Advance Block), [ta\_cdlbelthold](#ta_cdlbelthold) (Belt-hold), [ta\_cdlbreakaway](#ta_cdlbreakaway) (Breakaway), [ta\_cdlclosingmarubozu](#ta_cdlclosingmarubozu) (Closing Marubozu), [ta\_cdlconcealbabyswall](#ta_cdlconcealbabyswall) (Concealing Baby Swallow), [ta\_cdlcounterattack](#ta_cdlcounterattack) (Counterattack), [ta\_cdldarkcloudcover](#ta_cdldarkcloudcover) (Dark Cloud Cover), [ta\_cdldoji](#ta_cdldoji) (Doji), [ta\_cdldojistar](#ta_cdldojistar) (Doji Star), [ta\_cdldragonflydoji](#ta_cdldragonflydoji) (Dragonfly Doji), [ta\_cdlengulfing](#ta_cdlengulfing) (Engulfing Pattern), [ta\_cdleveningdojistar](#ta_cdleveningdojistar) (Evening Doji Star), [ta\_cdleveningstar](#ta_cdleveningstar) (Evening Star), [ta\_cdlgapsidesidewhite](#ta_cdlgapsidesidewhite) (Up/Down-gap side-by-side white lines), [ta\_cdlgravestonedoji](#ta_cdlgravestonedoji) (Gravestone Doji), [ta\_cdlhammer](#ta_cdlhammer) (Hammer), [ta\_cdlhangingman](#ta_cdlhangingman) (Hanging Man), [ta\_cdlharami](#ta_cdlharami) (Harami Pattern), [ta\_cdlharamicross](#ta_cdlharamicross) (Harami Cross Pattern), [ta\_cdlhighwave](#ta_cdlhighwave) (High-Wave Candle), [ta\_cdlhikkake](#ta_cdlhikkake) (Hikkake Pattern), [ta\_cdlhikkakemod](#ta_cdlhikkakemod) (Modified Hikkake Pattern), [ta\_cdlhomingpigeon](#ta_cdlhomingpigeon) (Homing Pigeon), [ta\_cdlidentical3crows](#ta_cdlidentical3crows) (Identical Three Crows), [ta\_cdlinneck](#ta_cdlinneck) (In-Neck Pattern), [ta\_cdlinvertedhammer](#ta_cdlinvertedhammer) (Inverted Hammer), [ta\_cdlkicking](#ta_cdlkicking) (Kicking), [ta\_cdlkickingbylength](#ta_cdlkickingbylength) (Kicking - bull/bear determined by the longer marubozu), [ta\_cdlladderbottom](#ta_cdlladderbottom) (Ladder Bottom), [ta\_cdllongleggeddoji](#ta_cdllongleggeddoji) (Long Legged Doji), [ta\_cdllongline](#ta_cdllongline) (Long Line Candle), [ta\_cdlmarubozu](#ta_cdlmarubozu) (Marubozu), [ta\_cdlmatchinglow](#ta_cdlmatchinglow) (Matching Low), [ta\_cdlmathold](#ta_cdlmathold) (Mat Hold), [ta\_cdlmorningdojistar](#ta_cdlmorningdojistar) (Morning Doji Star), [ta\_cdlmorningstar](#ta_cdlmorningstar) (Morning Star), [ta\_cdlonneck](#ta_cdlonneck) (On-Neck Pattern), [ta\_cdlpiercing](#ta_cdlpiercing) (Piercing Pattern), [ta\_cdlrickshawman](#ta_cdlrickshawman) (Rickshaw Man), [ta\_cdlrisefall3methods](#ta_cdlrisefall3methods) (Rising/Falling Three Methods), [ta\_cdlseparatinglines](#ta_cdlseparatinglines) (Separating Lines), [ta\_cdlshootingstar](#ta_cdlshootingstar) (Shooting Star), [ta\_cdlshortline](#ta_cdlshortline) (Short Line Candle), [ta\_cdlspinningtop](#ta_cdlspinningtop) (Spinning Top), [ta\_cdlstalledpattern](#ta_cdlstalledpattern) (Stalled Pattern), [ta\_cdlsticksandwich](#ta_cdlsticksandwich) (Stick Sandwich), [ta\_cdltakuri](#ta_cdltakuri) (Takuri (Dragonfly Doji with very long lower shadow)), [ta\_cdltasukigap](#ta_cdltasukigap) (Tasuki Gap), [ta\_cdlthrusting](#ta_cdlthrusting) (Thrusting Pattern), [ta\_cdltristar](#ta_cdltristar) (Tristar Pattern), [ta\_cdlunique3river](#ta_cdlunique3river) (Unique 3 River), [ta\_cdlupsidegap2crows](#ta_cdlupsidegap2crows) (Upside Gap Two Crows), [ta\_cdlxsidegap3methods](#ta_cdlxsidegap3methods) (Upside/Downside Gap Three Methods)

## Group: Statistic Functions

[ta\_beta](#ta_beta) (Beta), [ta\_correl](#ta_correl) (Pearson's Correlation Coefficient (r)), [ta\_linearreg](#ta_linearreg) (Linear Regression), [ta\_linearreg\_angle](#ta_linearreg_angle) (Linear Regression Angle), [ta\_linearreg\_intercept](#ta_linearreg_intercept) (Linear Regression Intercept), [ta\_linearreg\_slope](#ta_linearreg_slope) (Linear Regression Slope), [ta\_stddev](#ta_stddev) (Standard Deviation), [ta\_tsf](#ta_tsf) (Time Series Forecast), [ta\_var](#ta_var) (Variance)

## Group: Price Transform

[ta\_avgprice](#ta_avgprice) (Average Price), [ta\_medprice](#ta_medprice) (Median Price), [ta\_typprice](#ta_typprice) (Typical Price), [ta\_wclprice](#ta_wclprice) (Weighted Close Price)

# HANDLING BAD VALUES

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

# FUNCTIONS

## ta\_bbands

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

ta\_bbands processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_dema

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Double Exponential Moving Average

     $outpdl = ta_dema($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_dema processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ema

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Exponential Moving Average

     $outpdl = ta_ema($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_ema processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_trendline

    Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Instantaneous Trendline

     $outpdl = ta_ht_trendline($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outpdl - 1D piddle

ta\_ht\_trendline processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_kama

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Kaufman Adaptive Moving Average

     $outpdl = ta_kama($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_kama processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ma

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

ta\_ma processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_mama

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

ta\_mama processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_mavp

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

ta\_mavp processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_midpoint

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

MidPoint over period

     $outpdl = ta_midpoint($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_midpoint processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_midprice

    Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Midpoint Price over period

     $outpdl = ta_midprice($high, $low, $InTimePeriod);

    # $high, $low - 1D piddles, both have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_midprice processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_sar

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

ta\_sar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_sarext

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

ta\_sarext processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_sma

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Simple Moving Average

     $outpdl = ta_sma($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_sma processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_t3

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

ta\_t3 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_tema

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Triple Exponential Moving Average

     $outpdl = ta_tema($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_tema processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_trima

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Triangular Moving Average

     $outpdl = ta_trima($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_trima processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_wma

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Weighted Moving Average

     $outpdl = ta_wma($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_wma processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_atr

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average True Range

     $outpdl = ta_atr($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_atr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_natr

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Normalized Average True Range

     $outpdl = ta_natr($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_natr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_trange

    Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

True Range

     $outpdl = ta_trange($high, $low, $close);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_trange processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_adx

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average Directional Movement Index

     $outpdl = ta_adx($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_adx processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_adxr

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Average Directional Movement Index Rating

     $outpdl = ta_adxr($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_adxr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_apo

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

ta\_apo processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_aroon

    Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outAroonDown(n); double [o]outAroonUp(n))

Aroon

     ($outAroonDown, $outAroonUp) = ta_aroon($high, $low, $InTimePeriod);

    # $high, $low - 1D piddles, both have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outAroonDown - 1D piddle
    # returns: $outAroonUp - 1D piddle

ta\_aroon processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_aroonosc

    Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Aroon Oscillator

     $outpdl = ta_aroonosc($high, $low, $InTimePeriod);

    # $high, $low - 1D piddles, both have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_aroonosc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_bop

    Signature: (double open(n); double high(n); double low(n); double close(n); double [o]outpdl(n))

Balance Of Power

     $outpdl = ta_bop($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_bop processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cci

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Commodity Channel Index

     $outpdl = ta_cci($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_cci processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cmo

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Chande Momentum Oscillator

     $outpdl = ta_cmo($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_cmo processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_dx

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Directional Movement Index

     $outpdl = ta_dx($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_dx processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_macd

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

ta\_macd processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_macdext

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

ta\_macdext processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_macdfix

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

ta\_macdfix processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_mfi

    Signature: (double high(n); double low(n); double close(n); double volume(n); int InTimePeriod(); double [o]outpdl(n))

Money Flow Index

     $outpdl = ta_mfi($high, $low, $close, $volume, $InTimePeriod);

    # $high, $low, $close, $volume - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_mfi processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_minus\_di

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Minus Directional Indicator

     $outpdl = ta_minus_di($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_minus\_di processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_minus\_dm

    Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Minus Directional Movement

     $outpdl = ta_minus_dm($high, $low, $InTimePeriod);

    # $high, $low - 1D piddles, both have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_minus\_dm processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_mom

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Momentum

     $outpdl = ta_mom($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 10
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_mom processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_plus\_di

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Plus Directional Indicator

     $outpdl = ta_plus_di($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_plus\_di processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_plus\_dm

    Signature: (double high(n); double low(n); int InTimePeriod(); double [o]outpdl(n))

Plus Directional Movement

     $outpdl = ta_plus_dm($high, $low, $InTimePeriod);

    # $high, $low - 1D piddles, both have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_plus\_dm processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ppo

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

ta\_ppo processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_roc

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change : ((price/prevPrice-1)\*100)

     $outpdl = ta_roc($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 10
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_roc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_rocp

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change Percentage: (price-prevPrice/prevPrice)

     $outpdl = ta_rocp($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 10
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_rocp processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_rocr

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change ratio: (price/prevPrice)

     $outpdl = ta_rocr($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 10
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_rocr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_rocr100

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Rate of change ratio 100 scale: (price/prevPrice\*100)

     $outpdl = ta_rocr100($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 10
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_rocr100 processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_rsi

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Relative Strength Index

     $outpdl = ta_rsi($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_rsi processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_stoch

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

ta\_stoch processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_stochf

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

ta\_stochf processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_stochrsi

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

ta\_stochrsi processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_trix

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

1-day Rate-Of-Change (ROC of a Triple Smooth EMA)

     $outpdl = ta_trix($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_trix processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ultosc

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

ta\_ultosc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_willr

    Signature: (double high(n); double low(n); double close(n); int InTimePeriod(); double [o]outpdl(n))

Williams' %R

     $outpdl = ta_willr($high, $low, $close, $InTimePeriod);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_willr processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_dcperiod

    Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Dominant Cycle Period

     $outpdl = ta_ht_dcperiod($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outpdl - 1D piddle

ta\_ht\_dcperiod processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_dcphase

    Signature: (double inpdl(n); double [o]outpdl(n))

Hilbert Transform - Dominant Cycle Phase

     $outpdl = ta_ht_dcphase($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outpdl - 1D piddle

ta\_ht\_dcphase processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_phasor

    Signature: (double inpdl(n); double [o]outInPhase(n); double [o]outQuadrature(n))

Hilbert Transform - Phasor Components

     ($outInPhase, $outQuadrature) = ta_ht_phasor($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outInPhase - 1D piddle
    # returns: $outQuadrature - 1D piddle

ta\_ht\_phasor processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_sine

    Signature: (double inpdl(n); double [o]outSine(n); double [o]outLeadSine(n))

Hilbert Transform - SineWave

     ($outSine, $outLeadSine) = ta_ht_sine($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outSine - 1D piddle
    # returns: $outLeadSine - 1D piddle

ta\_ht\_sine processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ht\_trendmode

    Signature: (double inpdl(n); int [o]outInteger(n))

Hilbert Transform - Trend vs Cycle Mode

     $outInteger = ta_ht_trendmode($inpdl);

    # $inpdl - 1D piddle with input data
    # returns: $outInteger - 1D piddle

ta\_ht\_trendmode processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_ad

    Signature: (double high(n); double low(n); double close(n); double volume(n); double [o]outpdl(n))

Chaikin A/D Line

     $outpdl = ta_ad($high, $low, $close, $volume);

    # $high, $low, $close, $volume - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_ad processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_adosc

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

ta\_adosc processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_obv

    Signature: (double inpdl(n); double volume(n); double [o]outpdl(n))

On Balance Volume

     $outpdl = ta_obv($inpdl, $volume);

    # $inpdl - 1D piddle with input data
    # $volume - 1D piddle
    # returns: $outpdl - 1D piddle

ta\_obv processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl2crows

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Two Crows

     $outInteger = ta_cdl2crows($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl2crows processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3blackcrows

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Black Crows

     $outInteger = ta_cdl3blackcrows($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3blackcrows processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3inside

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Inside Up/Down

     $outInteger = ta_cdl3inside($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3inside processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3linestrike

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three-Line Strike

     $outInteger = ta_cdl3linestrike($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3linestrike processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3outside

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Outside Up/Down

     $outInteger = ta_cdl3outside($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3outside processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3starsinsouth

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Stars In The South

     $outInteger = ta_cdl3starsinsouth($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3starsinsouth processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdl3whitesoldiers

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Three Advancing White Soldiers

     $outInteger = ta_cdl3whitesoldiers($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdl3whitesoldiers processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlabandonedbaby

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Abandoned Baby

     $outInteger = ta_cdlabandonedbaby($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.3
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdlabandonedbaby processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdladvanceblock

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Advance Block

     $outInteger = ta_cdladvanceblock($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdladvanceblock processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlbelthold

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Belt-hold

     $outInteger = ta_cdlbelthold($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlbelthold processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlbreakaway

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Breakaway

     $outInteger = ta_cdlbreakaway($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlbreakaway processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlclosingmarubozu

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Closing Marubozu

     $outInteger = ta_cdlclosingmarubozu($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlclosingmarubozu processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlconcealbabyswall

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Concealing Baby Swallow

     $outInteger = ta_cdlconcealbabyswall($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlconcealbabyswall processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlcounterattack

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Counterattack

     $outInteger = ta_cdlcounterattack($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlcounterattack processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdldarkcloudcover

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Dark Cloud Cover

     $outInteger = ta_cdldarkcloudcover($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.5
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdldarkcloudcover processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdldoji

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Doji

     $outInteger = ta_cdldoji($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdldoji processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdldojistar

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Doji Star

     $outInteger = ta_cdldojistar($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdldojistar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdldragonflydoji

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Dragonfly Doji

     $outInteger = ta_cdldragonflydoji($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdldragonflydoji processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlengulfing

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Engulfing Pattern

     $outInteger = ta_cdlengulfing($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlengulfing processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdleveningdojistar

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Evening Doji Star

     $outInteger = ta_cdleveningdojistar($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.3
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdleveningdojistar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdleveningstar

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Evening Star

     $outInteger = ta_cdleveningstar($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.3
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdleveningstar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlgapsidesidewhite

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Up/Down-gap side-by-side white lines

     $outInteger = ta_cdlgapsidesidewhite($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlgapsidesidewhite processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlgravestonedoji

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Gravestone Doji

     $outInteger = ta_cdlgravestonedoji($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlgravestonedoji processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhammer

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hammer

     $outInteger = ta_cdlhammer($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhammer processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhangingman

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hanging Man

     $outInteger = ta_cdlhangingman($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhangingman processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlharami

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Harami Pattern

     $outInteger = ta_cdlharami($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlharami processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlharamicross

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Harami Cross Pattern

     $outInteger = ta_cdlharamicross($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlharamicross processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhighwave

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

High-Wave Candle

     $outInteger = ta_cdlhighwave($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhighwave processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhikkake

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Hikkake Pattern

     $outInteger = ta_cdlhikkake($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhikkake processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhikkakemod

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Modified Hikkake Pattern

     $outInteger = ta_cdlhikkakemod($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhikkakemod processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlhomingpigeon

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Homing Pigeon

     $outInteger = ta_cdlhomingpigeon($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlhomingpigeon processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlidentical3crows

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Identical Three Crows

     $outInteger = ta_cdlidentical3crows($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlidentical3crows processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlinneck

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

In-Neck Pattern

     $outInteger = ta_cdlinneck($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlinneck processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlinvertedhammer

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Inverted Hammer

     $outInteger = ta_cdlinvertedhammer($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlinvertedhammer processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlkicking

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Kicking

     $outInteger = ta_cdlkicking($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlkicking processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlkickingbylength

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Kicking - bull/bear determined by the longer marubozu

     $outInteger = ta_cdlkickingbylength($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlkickingbylength processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlladderbottom

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Ladder Bottom

     $outInteger = ta_cdlladderbottom($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlladderbottom processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdllongleggeddoji

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Long Legged Doji

     $outInteger = ta_cdllongleggeddoji($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdllongleggeddoji processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdllongline

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Long Line Candle

     $outInteger = ta_cdllongline($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdllongline processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlmarubozu

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Marubozu

     $outInteger = ta_cdlmarubozu($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlmarubozu processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlmatchinglow

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Matching Low

     $outInteger = ta_cdlmatchinglow($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlmatchinglow processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlmathold

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Mat Hold

     $outInteger = ta_cdlmathold($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.5
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdlmathold processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlmorningdojistar

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Morning Doji Star

     $outInteger = ta_cdlmorningdojistar($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.3
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdlmorningdojistar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlmorningstar

    Signature: (double open(n); double high(n); double low(n); double close(n); double InPenetration(); int [o]outInteger(n))

Morning Star

     $outInteger = ta_cdlmorningstar($open, $high, $low, $close, $InPenetration);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # $InPenetration [Percentage of penetration of a candle within another candle] - real number
    #     default: 0.3
    #     valid range: min=0 max=3e+037
    # returns: $outInteger - 1D piddle

ta\_cdlmorningstar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlonneck

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

On-Neck Pattern

     $outInteger = ta_cdlonneck($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlonneck processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlpiercing

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Piercing Pattern

     $outInteger = ta_cdlpiercing($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlpiercing processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlrickshawman

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Rickshaw Man

     $outInteger = ta_cdlrickshawman($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlrickshawman processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlrisefall3methods

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Rising/Falling Three Methods

     $outInteger = ta_cdlrisefall3methods($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlrisefall3methods processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlseparatinglines

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Separating Lines

     $outInteger = ta_cdlseparatinglines($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlseparatinglines processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlshootingstar

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Shooting Star

     $outInteger = ta_cdlshootingstar($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlshootingstar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlshortline

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Short Line Candle

     $outInteger = ta_cdlshortline($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlshortline processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlspinningtop

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Spinning Top

     $outInteger = ta_cdlspinningtop($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlspinningtop processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlstalledpattern

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Stalled Pattern

     $outInteger = ta_cdlstalledpattern($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlstalledpattern processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlsticksandwich

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Stick Sandwich

     $outInteger = ta_cdlsticksandwich($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlsticksandwich processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdltakuri

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Takuri (Dragonfly Doji with very long lower shadow)

     $outInteger = ta_cdltakuri($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdltakuri processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdltasukigap

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Tasuki Gap

     $outInteger = ta_cdltasukigap($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdltasukigap processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlthrusting

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Thrusting Pattern

     $outInteger = ta_cdlthrusting($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlthrusting processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdltristar

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Tristar Pattern

     $outInteger = ta_cdltristar($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdltristar processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlunique3river

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Unique 3 River

     $outInteger = ta_cdlunique3river($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlunique3river processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlupsidegap2crows

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Upside Gap Two Crows

     $outInteger = ta_cdlupsidegap2crows($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlupsidegap2crows processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_cdlxsidegap3methods

    Signature: (double open(n); double high(n); double low(n); double close(n); int [o]outInteger(n))

Upside/Downside Gap Three Methods

     $outInteger = ta_cdlxsidegap3methods($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outInteger - 1D piddle

ta\_cdlxsidegap3methods processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_beta

    Signature: (double inpdl0(n); double inpdl1(n); int InTimePeriod(); double [o]outpdl(n))

Beta

     $outpdl = ta_beta($inpdl0, $inpdl1, $InTimePeriod);

    # $inpdl0 - 1D piddle
    # $inpdl1 - 1D piddle
    # $InTimePeriod [Number of period] - integer
    #     default: 5
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_beta processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_correl

    Signature: (double inpdl0(n); double inpdl1(n); int InTimePeriod(); double [o]outpdl(n))

Pearson's Correlation Coefficient (r)

     $outpdl = ta_correl($inpdl0, $inpdl1, $InTimePeriod);

    # $inpdl0 - 1D piddle
    # $inpdl1 - 1D piddle
    # $InTimePeriod [Number of period] - integer
    #     default: 30
    #     valid range: min=1 max=100000
    # returns: $outpdl - 1D piddle

ta\_correl processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_linearreg

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression

     $outpdl = ta_linearreg($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_linearreg processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_linearreg\_angle

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Angle

     $outpdl = ta_linearreg_angle($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_linearreg\_angle processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_linearreg\_intercept

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Intercept

     $outpdl = ta_linearreg_intercept($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_linearreg\_intercept processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_linearreg\_slope

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Linear Regression Slope

     $outpdl = ta_linearreg_slope($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_linearreg\_slope processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_stddev

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

ta\_stddev processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_tsf

    Signature: (double inpdl(n); int InTimePeriod(); double [o]outpdl(n))

Time Series Forecast

     $outpdl = ta_tsf($inpdl, $InTimePeriod);

    # $inpdl - 1D piddle with input data
    # $InTimePeriod [Number of period] - integer
    #     default: 14
    #     valid range: min=2 max=100000
    # returns: $outpdl - 1D piddle

ta\_tsf processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_var

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

ta\_var processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_avgprice

    Signature: (double open(n); double high(n); double low(n); double close(n); double [o]outpdl(n))

Average Price

     $outpdl = ta_avgprice($open, $high, $low, $close);

    # $open, $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_avgprice processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_medprice

    Signature: (double high(n); double low(n); double [o]outpdl(n))

Median Price

     $outpdl = ta_medprice($high, $low);

    # $high, $low - 1D piddles, both have to be the same size
    # returns: $outpdl - 1D piddle

ta\_medprice processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_typprice

    Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

Typical Price

     $outpdl = ta_typprice($high, $low, $close);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_typprice processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

## ta\_wclprice

    Signature: (double high(n); double low(n); double close(n); double [o]outpdl(n))

Weighted Close Price

     $outpdl = ta_wclprice($high, $low, $close);

    # $high, $low, $close - 1D piddles, all have to be the same size
    # returns: $outpdl - 1D piddle

ta\_wclprice processes bad values.
It will set the bad-value flag of all output ndarrays if the flag is set for any of the input ndarrays.

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
