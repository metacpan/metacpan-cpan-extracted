// Example of Perl object macros.

! version = 2.0

> object base64 perl
    my ($rs, @args) = @_;
    use MIME::Base64 qw(encode_base64);
    return encode_base64(join(" ", @args));
< object

> object setvar perl
    my ($rs, @args) = @_;

    # This function demonstrates using currentUser() to get
    # the current user ID, to set a variable for them.
    my $uid   = $rs->currentUser();
    my $var   = shift(@args);
    my $value = join(" ", @args);
    $rs->setUservar($uid, $var, $value);
    return "";
< object

+ encode * in base64
- OK: <call>base64 <star></call>

+ perl set * to *
- Setting user variable <star1> to <star2>.<call>setvar <star1> <star2></call>
