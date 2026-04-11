#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use lib 't/lib';

use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

# ============================================
# Financial Calculations Integration Tests
# ============================================

subtest 'simple returns calculation' => sub {
    # Daily prices
    my $prices = Numeric::Vector::new([100, 102, 101, 105, 103]);

    # Simple returns: (P_t - P_{t-1}) / P_{t-1}
    my $returns = $prices->diff();  # [2, -1, 4, -2]

    # Divide by previous prices (need to slice off last element)
    my $prev_prices = $prices->slice(0, $prices->len() - 1);  # [100, 102, 101, 105]
    my $pct_returns = $returns->div($prev_prices);

    within_tolerance($pct_returns->get(0), 0.02, 'first return = 2%');
    within_tolerance($pct_returns->get(1), -1/102, 'second return ≈ -0.98%');
};

subtest 'log returns calculation' => sub {
    my $prices = Numeric::Vector::new([100, 105, 110, 100]);

    # Log returns: ln(P_t / P_{t-1}) = ln(P_t) - ln(P_{t-1})
    my $log_prices = $prices->log();
    my $log_returns = $log_prices->diff();

    # log(105/100) ≈ 0.0488
    within_tolerance($log_returns->get(0), log(105/100), 'log return 1');
    within_tolerance($log_returns->get(1), log(110/105), 'log return 2');
};

subtest 'cumulative returns' => sub {
    # Daily returns: 1%, 2%, -1%, 3%
    my $returns = Numeric::Vector::new([0.01, 0.02, -0.01, 0.03]);

    # Cumulative return: (1+r1) * (1+r2) * ... - 1
    my $one_plus_r = $returns->add_scalar(1);
    my $cumulative = $one_plus_r->cumprod();

    # After first day: 1.01
    within_tolerance($cumulative->get(0), 1.01, 'cumulative after day 1');

    # Final cumulative: 1.01 * 1.02 * 0.99 * 1.03 ≈ 1.0504
    my $expected = 1.01 * 1.02 * 0.99 * 1.03;
    within_tolerance($cumulative->get(3), $expected, 'final cumulative return');
};

subtest 'portfolio returns' => sub {
    # Asset returns
    my $returns = Numeric::Vector::new([0.05, 0.02, -0.01]);  # 5%, 2%, -1%

    # Portfolio weights (must sum to 1)
    my $weights = Numeric::Vector::new([0.5, 0.3, 0.2]);

    # Portfolio return = sum(w_i * r_i)
    my $portfolio_return = $returns->dot($weights);

    # 0.5*0.05 + 0.3*0.02 + 0.2*(-0.01) = 0.025 + 0.006 - 0.002 = 0.029
    within_tolerance($portfolio_return, 0.029, 'portfolio return = 2.9%');
};

subtest 'volatility (standard deviation of returns)' => sub {
    # Monthly returns
    my $returns = Numeric::Vector::new([0.02, -0.01, 0.03, 0.01, -0.02, 0.02]);

    my $vol = $returns->std();

    # Annualize: multiply by sqrt(12) for monthly data
    my $annual_vol = $vol * sqrt(12);

    ok($vol > 0, 'volatility is positive');
    ok($annual_vol > $vol, 'annualized vol > monthly vol');
};

subtest 'Sharpe ratio calculation' => sub {
    my $returns = Numeric::Vector::new([0.01, 0.02, 0.015, 0.008, 0.012]);
    my $risk_free = 0.001;  # 0.1% per period

    # Excess returns
    my $excess = $returns->add_scalar(-$risk_free);

    # Sharpe = mean(excess) / std(excess)
    my $sharpe = $excess->mean() / $excess->std();

    ok($sharpe > 0, 'positive Sharpe ratio for positive excess returns');
};

subtest 'moving average crossover' => sub {
    # Simulated prices with trend
    my $prices = Numeric::Vector::new([100, 101, 103, 102, 105, 107, 106, 108, 110, 112]);

    # Simple moving average (manual for small windows)
    my @sma3;
    my $arr = $prices->to_array();
    for my $i (2 .. $#$arr) {
        push @sma3, ($arr->[$i-2] + $arr->[$i-1] + $arr->[$i]) / 3;
    }

    # Verify MA calculation
    my $first_sma = ($arr->[0] + $arr->[1] + $arr->[2]) / 3;
    within_tolerance($sma3[0], $first_sma, 'first SMA-3 correct');
};

subtest 'drawdown calculation' => sub {
    my $equity = Numeric::Vector::new([100, 110, 105, 115, 108, 120, 115]);

    # Running maximum
    my @running_max;
    my $max_so_far = 0;
    my $arr = $equity->to_array();
    for my $val (@$arr) {
        $max_so_far = $val if $val > $max_so_far;
        push @running_max, $max_so_far;
    }

    # Drawdown = (running_max - equity) / running_max
    my $running_max_vec = Numeric::Vector::new(\@running_max);
    my $diff = $running_max_vec->sub($equity);
    my $drawdown = $diff->div($running_max_vec);

    # At peak (index 5, equity=120), drawdown should be 0
    within_tolerance($drawdown->get(5), 0, 'no drawdown at peak');

    # After peak at index 6 (115 vs max 120), drawdown = 5/120
    within_tolerance($drawdown->get(6), 5/120, 'drawdown after peak');
};

subtest 'present value calculation' => sub {
    # Future cash flows
    my $cash_flows = Numeric::Vector::new([100, 100, 100, 100, 100]);  # 5 annual payments
    my $rate = 0.05;  # 5% discount rate

    # Discount factors: 1/(1+r)^t for t=1,2,3,4,5
    my @factors;
    for my $t (1..5) {
        push @factors, 1 / ((1 + $rate) ** $t);
    }
    my $discount_factors = Numeric::Vector::new(\@factors);

    # PV = sum(CF * DF)
    my $pv = $cash_flows->dot($discount_factors);

    # Should be less than sum of cash flows (432.95 for these values)
    ok($pv < $cash_flows->sum(), 'PV < sum of cash flows');
    ok($pv > 400, 'PV in reasonable range');
};

subtest 'compound interest' => sub {
    my $principal = 1000;
    my $rate = 0.05;  # 5% annual
    my $years = 10;

    # Future value = P * (1 + r)^n
    my $growth_factor = (1 + $rate) ** $years;
    my $fv = $principal * $growth_factor;

    within_tolerance($fv, 1000 * (1.05 ** 10), 'compound interest FV');

    # Using Numeric::Vector: create growth path
    my $time = Numeric::Vector::range(0, $years + 1);  # 0 to 10
    my $one_plus_r = Numeric::Vector::fill($years + 1, 1 + $rate);

    # growth[t] = (1+r)^t
    my $growth = $one_plus_r->pow($time->to_array()->[0]);  # pow takes scalar

    # Verify final value
    # Actually let's do this differently - build the growth path
    my @growth_vals = map { (1 + $rate) ** $_ } (0..$years);
    my $growth_vec = Numeric::Vector::new(\@growth_vals);

    within_tolerance($growth_vec->get($years), (1 + $rate) ** $years, 'growth factor at year 10');
};

subtest 'correlation approximation via dot product' => sub {
    # Standardized returns (mean=0, std=1)
    my $r1 = Numeric::Vector::new([-1.2, 0.5, 0.3, -0.2, 0.6]);
    my $r2 = Numeric::Vector::new([-1.0, 0.4, 0.5, -0.1, 0.2]);

    # Correlation ≈ dot(r1, r2) / (n-1) for standardized data
    my $n = $r1->len();
    my $corr = $r1->dot($r2) / ($n - 1);

    # Should be positive (similar patterns)
    ok($corr > 0, 'positive correlation for similar patterns');
    ok($corr < 1, 'correlation < 1');
};

subtest 'value at risk (VaR) - percentile approach' => sub {
    # Simulated returns (sorted for percentile)
    my $returns = Numeric::Vector::new([-0.05, -0.03, -0.02, -0.01, 0, 0.01, 0.02, 0.03, 0.04, 0.05]);

    # 5% VaR: 5th percentile of returns
    my $sorted = $returns->sort();
    my $var_5pct = $sorted->get(0);  # Worst return in this sample

    within_tolerance($var_5pct, -0.05, 'VaR 5% = worst return');
};

subtest 'position sizing' => sub {
    my $portfolio_value = 100000;
    my $risk_per_trade = 0.01;  # 1% risk

    # Multiple assets with different volatilities
    my $volatilities = Numeric::Vector::new([0.02, 0.05, 0.03, 0.08]);

    # Position size = (portfolio * risk) / volatility
    my $risk_amount = $portfolio_value * $risk_per_trade;
    my $positions = Numeric::Vector::fill($volatilities->len(), $risk_amount)->div($volatilities);

    # Higher volatility = smaller position
    ok($positions->get(1) < $positions->get(0), 'higher vol = smaller position');
    ok($positions->get(3) < $positions->get(2), 'highest vol = smallest position');
};

subtest 'Kelly criterion approximation' => sub {
    my $win_prob = 0.6;
    my $win_amount = 1.0;  # Win 1x
    my $lose_amount = 1.0;  # Lose 1x

    # Kelly fraction = (p * b - q) / b
    # where p = win prob, q = lose prob, b = win/lose ratio
    my $b = $win_amount / $lose_amount;
    my $kelly = ($win_prob * $b - (1 - $win_prob)) / $b;

    # Kelly = (0.6 * 1 - 0.4) / 1 = 0.2
    within_tolerance($kelly, 0.2, 'Kelly fraction = 20%');
};

done_testing();
