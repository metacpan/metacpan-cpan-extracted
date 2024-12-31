# NAME

SMS::Send::VoIP::MS - SMS::Send driver for VoIP.ms Web Services

# SYNOPSIS

     Configure /etc/SMS-Send.ini
    
     [VoIP::MS]
     username=myuser
     password=mypass
     did=8005550123
    
     use SMS::Send;
     my $sms     = SMS::Send->new('VoIP::MS');
     my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');
    
     use SMS::Send::VoIP::MS;
     my $sms     = SMS::Send::VoIP::MS->new;
     my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');
     my $json    = $sms->{__content};
     my $href    = $sms->{__data};

# DESCRIPTION

SMS::Send driver for VoIP.ms Web Services.

# METHODS

## send\_sms

    my $success = $sms->send_sms(text=> 'Hello World!', to =>'+17035550123');

# PROPERTIES

## username

Sets and returns the username string value which is passed to the web service as "api\_username"

    $sms->username("override");

## password

Sets and returns the password string value which is passed to the web service as "api\_password"

    $sms->password("override");

## did

Sets and returns the "did" string value (Direct Inward Dialing Number aka the From Phone Number) which is passed to the web service as "did".

## url

Sets and returns the url for the web service.

Default: https://voip.ms/api/v1/rest.php

# SEE ALSO

[VoIPms](https://metacpan.org/pod/VoIPms), [https://www.voip.ms/m/apidocs.php](https://www.voip.ms/m/apidocs.php), [https://voip.ms/m/api.php](https://voip.ms/m/api.php)

# AUTHOR

Michael R. Davis, mrdvt92

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT
