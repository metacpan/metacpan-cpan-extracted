# Benchmark

    # first shell
    bench/App daemon 

    # other shell
    perl -Ilib bench/bench.pl


# Results

                     Rate      want_code simple_promise    bare_mojoua
    want_code      1057/s             --            -5%            -8%
    simple_promise 1109/s             5%             --            -3%
    bare_mojoua    1148/s             9%             4%             --

The performance overhead of a promise-way, even with `want_code` generator, in a real app is very tiny and can be ignored.
