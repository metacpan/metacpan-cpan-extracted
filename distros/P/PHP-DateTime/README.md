# NAME

PHP::DateTime - Clone of PHP's date and time functions.

# SYNOPSIS

```perl
use PHP::DateTime;

if( checkdate($month,$day,$year) ){ print 'The date is good.'; }

print date( $format, $time );
print date( $format ); # Defaults to the current time.

@d = getdate(); # A list at the current time.
@d = getdate($time); # A list at the specified time.
$d = getdate($time); # An array ref at the specified time.

my @g = gettimeofday(); # A list.
my $g = gettimeofday(); # An array ref.

my $then = mktime( $hour, $min, $sec, $month, $day, $year );
```

# DESCRIPTION

Duplicates some of PHP's date and time functions.  Why?  I can't remember. 
It should be useful if you are trying to integrate your perl app with a php app. 
Much like PHP this module gratuitously exports all its functions upon a use(). 
Neat, eh?

# METHODS

All of these methods should match PHP's methods exactly.

```
- Months are 1-12.
- Days are 1-31.
- Years are in four digit format (1997, not 97).
```

## checkdate

```
if( checkdate($month,$day,$year) ){ print 'The date is good.'; }
```

[http://php.net/manual/en/function.checkdate.php](http://php.net/manual/en/function.checkdate.php)

## date

```
print date( $format, $time );
print date( $format ); # Defaults to the current time.
```

[http://php.net/manual/en/function.date.php](http://php.net/manual/en/function.date.php)

## getdate

```
@d = getdate(); # A list at the current time.
@d = getdate($time); # A list at the specified time.
$d = getdate($time); # An array ref at the specified time.
```

[http://php.net/manual/en/function.getdate.php](http://php.net/manual/en/function.getdate.php)

## gettimeofday

```perl
my %g = gettimeofday(); # A hash.
my $g = gettimeofday(); # An hash ref.
```

[http://php.net/manual/en/function.gettimeofday.php](http://php.net/manual/en/function.gettimeofday.php)

## mktime

```perl
my $then = mktime( $hour, $min, $sec, $month, $day, $year );
```

[http://php.net/manual/en/function.mktime.php](http://php.net/manual/en/function.mktime.php)

# SEE ALSO

[http://php.net/manual/en/ref.datetime.php](http://php.net/manual/en/ref.datetime.php)

# AUTHOR

```
Aran Clary Deltac <bluefeet@gmail.com>
```

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
