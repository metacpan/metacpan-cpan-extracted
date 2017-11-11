**Progress::Awesome** - an awesome progress bar that just works

## Example

![Animated gif of progress bar in action](https://i.imgur.com/g2MeL7q.gif)

```perl
my $p = Progress::Awesome->new(items => 100, style => 'rainbow');
for my $item (1..100) {
    do_some_stuff();
    $p++;
}
```

## Description

Similar to the venerable [Term::ProgressBar](https://metacpan.org/pod/Term::ProgressBar) with several enhancements:

- Does the right thing when non-interactive - hides the progress bar and logs
intermittently with timestamps.
- Completes itself when `finish` is called or it goes out of scope, just in case
you forget.
- Customisable format includes number of items, item processing rate, file transfer
rate (if items=bytes) and ETA. When non-interactive, logging format can also be
customised.
- Gets out of your way - won't noisily complain if it can't work out the terminal
size, and won't die if you set the progress bar to its max value when it's already
reached the max (or for any other reason).
- Can be incremented using `++` or `+=` if you like.
- Works fine if max is undefined, set halfway through, or updated halfway through.
- Estimates ETA with more intelligent prediction than simple linear.
- Colours!!
- Multiple process bars at once 'just work'.

## Methods

- new ( %args )

    Create a new progress bar. (Arguments may also be passed as a hashref)

    - items (optional)

        Number of items in the progress bar.

    - format (default: '\[:bar\] :count/:items :eta :rate')

        Specify a format for the progress bar (see ["FORMATS"](#formats) below).
        The `:bar` part will fill to all available space.

    - style (optional)

        Specify the bar style. This may be a string ('rainbow' or 'boring') or a function
        that accepts the percentage and size of the bar (in chars) and returns ANSI data
        for the bar.

    - title (optional)

        Optional bar title.

    - log\_format (default: '\[:ts\] :percent% :count/:items :eta :rate')

        Specify a format for log output used when the script is run non-interactively.

    - log (default: 1)

        If set to 0, don't log anything when run non-interactively.

    - color (default: 1)

        If set to 0, suppress colors when rendering the progress bar.

    - remove (default: 0)

        If set to 1, remove the progress bar after completion via `finish`.

    - fh (default: \\\*STDERR)

        The filehandle to output to.

    - count (default: 0)

        Starting count.

- update ( value )

    Update the progress bar to the specified value. If undefined, the progress bar will go into
    a spinning/unknown state.

- inc ( \[value\] )

    Increment progress bar by this many items, or 1 if omitted.

- finish

    Set the progress bar to maximum. Any further updates will not take effect. Happens automatically
    when the progress bar goes out of scope.

- items ( \[value\] )

    Updates the number of items for the progress bar. May be set to undef if unknown. With zero
    arguments, returns the number of items.

- dec ( \[value\] )

    Decrement the progress bar by this many items, or 1 if omitted.

## Formats

Format strings may contain any of the below fields:

- :bar

    The progress bar. Expands to fill all available space not used by other fields.

- ::

    Literal ':'

- :ts

    Current timestamp (month, day, time) - intended for logging mode.

- :count

    Current item count.

- :items

    Maximum number of items

- :eta

    Estimated time until progress bar completes.

- :rate

    Number of items being processed per second.

- :bytes

    Number of bytes being processed per second (expressed as KB, MB, GB etc. as needed)

- :percent

    Current percent completion (without % sign)

## Reporting bugs

It's early days for this module so bugs are possible and feature requests are warmly
welcomed. We use [Github Issues](https://github.com/richardjharris/perl-Progress-Awesome/issues)
for reports.

## Author

Richard Harris richardjharris@gmail.com

## Copyright

Copyright (c) 2017 Richard Harris.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.
