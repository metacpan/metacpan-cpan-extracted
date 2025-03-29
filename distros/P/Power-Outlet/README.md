# File: lib/Power/Outlet.pm

## NAME

Power::Outlet - Control and query network attached power outlets

## SYNOPSIS

Command Line

    power-outlet Config    ON section "My Section"
    power-outlet iBoot     ON host mylamp
    power-outlet Hue       ON host mybridge id 1 username myuser
    power-outlet Shelly    ON host myshelly
    power-outlet SonoffDiy ON host mysonoff
    power-outlet Tasmota   ON host mytasmota
    power-outlet WeMo      ON host mywemo

Perl Object API

    my $outlet=Power::Outlet->new(                   #sane defaults from manufactures spec
                                  type => "iBoot",
                                  host => "mylamp",
                                 );
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet is a package for controlling and querying network attached power outlets.  Individual hardware drivers in this name space must provide a common object interface for the controlling and querying of an outlet.  Common methods that every network attached power outlet must know are on, off, query, switch and cycle.  Optional methods might be implemented in some drivers like amps and volts.

### SCOPE

The current scope of these packages is network attached power outlets. I started with iBoot and iBootBar since I had the hardware.  Hardware configuration is beyond the scope of this group of packages as most power outlets have functional web based or command line configuration tools.

### Home Assistant

Integration with Home Assistant [https://home-assistant.io/](https://home-assistant.io/) can be accomplished by configuring a Command Line Switch. 

    switch:
      - platform: command_line
        switches:
          ibootbar_1:
            command_on: /usr/bin/power-outlet iBootBar ON host mybar.local outlet 1
            command_off: /usr/bin/power-outlet iBootBar OFF host mybar.local outlet 1
            command_state: /usr/bin/power-outlet iBootBar QUERY host mybar.local outlet 1 | /bin/grep -q ON
            friendly_name: My iBootBar Outlet 1

See [https://home-assistant.io/components/switch.command\_line/](https://home-assistant.io/components/switch.command_line/)

### Node Red

Integration with Node Red [https://nodered.org/](https://nodered.org/) can be accomplished with the included JSON web API power-outlet-json.cgi.  The power-outlet-json.cgi script is a layer on top of [Power::Outlet::Config](https://metacpan.org/pod/Power::Outlet::Config) where the "name" parameter maps to the section in the /etc/power-outlet.ini INI file.

To access all of these devices use an http request node with a URL https://127.0.0.1/cgi-bin/power-outlet-json.cgi?name={{topic}};action={{payload}} then simply set the topic to the INI section and the action to either ON or OFF.

## USAGE

The Perl one liner

    perl -MPower::Outlet -e 'print Power::Outlet->new(type=>"Tasmota", host=>shift)->switch, "\n"' myhost

The included command line script

    power-outlet Shelly ON host myshelly

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"WeMo",     host=>"mywemo");

## BUGS

Please open an issue on github

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[Power::Outlet::iBoot](https://metacpan.org/pod/Power::Outlet::iBoot), [Power::Outlet::iBootBar](https://metacpan.org/pod/Power::Outlet::iBootBar), [Power::Outlet::WeMo](https://metacpan.org/pod/Power::Outlet::WeMo), [Power::Outlet::Hue](https://metacpan.org/pod/Power::Outlet::Hue)

# File: lib/Power/Outlet/Config.pm

## NAME

Power::Outlet::Config - Control and query a Power::Outlet device from Configuration file

## SYNOPSIS

    my $outlet = Power::Outlet::Config->new(section=>"My Section");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::Config is a package for controlling and querying Power::Outlet devices registered in an INI file.

## USAGE

Configuration

    /etc/power-outliet.ini
    [My Tasmota]
    type=Tasmota
    host=light-hostname
    relay=POWER

    [My SonoffDiy]
    type=SonoffDiy
    host=switch=hostname

Script

    use Power::Outlet::Config;
    my $outlet = Power::Outlet::Config->new(section=>"My Section");
    print $outlet->on, "\n";

Command Line

    /usr/bin/power-outlet Config ON section "My Tasmota"
    /usr/bin/power-outlet Config ON section "My Section" ini_file ./my.ini

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"Config", section=>"My Section");
    my $outlet = Power::Outlet::Config->new(section=>"My Section");

## PROPERTIES

### section

### hash

## OBJECT ACCESSORS

### ini

Returns a [Config::IniFiles](https://metacpan.org/pod/Config::IniFiles) for the power-outlet.ini file.

### ini\_file

Default: /etc/power-outlet.ini or C:\\Windows\\power-outlet.ini

### ini\_file\_default

Default: power-outlet.ini

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

# File: lib/Power/Outlet/Dingtian.pm

## NAME

Power::Outlet::Dingtian - Control and query Dingtian Relay Boards via the HTTP API

## SYNOPSIS

    my $outlet = Power::Outlet::Dingtian->new(host => "my_host", relay => "1");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::Dingtian is a package for controlling and querying a relay on Dingtian hardware via the HTTP API.

Example commands can be executed via web (HTTP) GET requests, for example:

Relay Status URL Example

    http://192.168.1.100/relay_cgi_load.cgi

Relay 1 on example (relays are named one-based but the api uses a zero-based index)

    http://192.168.1.100/relay_cgi.cgi?type=0&relay=0&on=1&time=0&pwd=0&

Relay 2 off example

    http://192.168.1.100/relay_cgi.cgi?type=0&relay=1&on=0&time=0&pwd=0&

Relay 2 cycle off-on-off example (note: time in 100ms increments)

    http://192.168.1.100/relay_cgi.cgi?type=1&relay=1&on=1&time=100&pwd=0&

I have tested this package against the Dingtian DT-R002 V3.6A with V3.1.276A firmware configured for both HTTP and HTTPS.

## USAGE

    use Power::Outlet::Dingtian;
    my $relay = Power::Outlet::Dingtian->new(host=>"my_host", relay=>"1");
    print $relay->on, "\n";

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"Dingtian", host=>"my_host", relay=>"1");
    my $outlet = Power::Outlet::Dingtian->new(host=>"my_host", relay=>"1");

## PROPERTIES

### relay

Dingtian API supports up to 32 relays numbered 1 to 32.

Default: 1

Note: The relays are numbered 1-32 but the api uses a zero based index.

### pwd

Sets and returns the ID token used for authentication with the Dingtian hardware

Default: "0"

Can be set in the Relay Password property in the Other section on the Relay Connect screen.

### host

Sets and returns the hostname or IP address.

Default: 192.168.1.100

### port

Sets and returns the port number.

Default: 80

Can be set in the HTTP Server Port property on the Setting screen.

### http\_scheme

Sets and returns the http scheme (i.e. protocol) (e.g. http or https).

Default: http

Can be set in the HTTP or HTTPS property on the Setting screen

## METHODS

### name

Sets and returns the friendly name for this relay.

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

Sends a message to the device to toggle the power

### cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

## BUGS

Please open an issue on GitHub.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[https://www.dingtian-tech.com/sdk/relay\_sdk.zip](https://www.dingtian-tech.com/sdk/relay_sdk.zip) => programming\_manual\_en.pdf page 12 "Protocol: HTTP GET CGI"

# File: lib/Power/Outlet/Hue.pm

## NAME

Power::Outlet::Hue - Control and query a Philips Hue light

## SYNOPSIS

    my $outlet=Power::Outlet::Hue->new(host => "mybridge", id=>1, username=>"myuser");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::Hue is a package for controlling and querying a light on a Philips Hue network attached bridge.

## USAGE

    use Power::Outlet::Hue;
    my $lamp=Power::Outlet::Hue->new(host=>"mybridge", id=>1, username=>"myuser");
    print $lamp->on, "\n";

## CONSTRUCTOR

### new

    my $outlet=Power::Outlet->new(type=>"Hue", host=>"mybridge", id=>1);
    my $outlet=Power::Outlet::Hue->new(host=>"mybridge", id=>1);

## PROPERTIES

### id

ID for the particular light as configured in the Philips Hue Bridge

Default: 1

### resource

Resource for the particular object as presented on the Philips Hue Bridge

Default: lights

Currently supported Resources from [https://developers.meethue.com/documentation/core-concepts](https://developers.meethue.com/documentation/core-concepts)

    lights    - resource which contains all the light resources
    groups    - resource which contains all the groups
    config    - resource which contains all the configuration items
    schedules - which contains all the schedules
    scenes    - which contains all the scenes
    sensors   - which contains all the sensors
    rules     - which contains all the rules

### host

Sets and returns the hostname or IP address.

Default: mybridge

### port

Sets and returns the port number.

Default: 80

### username

Sets and returns the username used for authentication with the Hue Bridge

Default: newdeveloper (Hue Emulator default)

### name

Returns the configured friendly name for the device

## METHODS

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

Queries the device for the current status and then requests the opposite.

### cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

Thanks to Mathias Neerup manee12 at student.sdu.dk - [https://rt.cpan.org/Ticket/Display.html?id=123965](https://rt.cpan.org/Ticket/Display.html?id=123965)

## COPYRIGHT

Copyright (c) 2018 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[http://www.developers.meethue.com/philips-hue-api](http://www.developers.meethue.com/philips-hue-api), [http://steveyo.github.io/Hue-Emulator/](http://steveyo.github.io/Hue-Emulator/), [https://home-assistant.io/components/emulated\_hue/](https://home-assistant.io/components/emulated_hue/)

# File: lib/Power/Outlet/MQTT.pm

## NAME

Power::Outlet::MQTT - Control and query an outlet or relay via MQTT

## SYNOPSIS

Tasmota defaults

    my $outlet = Power::Outlet::MQTT->new(
                                          host                => "mqtt",
                                          device              => "my_device",
                                          relay               => "POWER1",
                                         );

or topic defaults

    my $outlet = Power::Outlet::MQTT->new(
                                          host                => "mqtt",
                                          publish_topic       => "cmnd/my_device/POWER1",
                                          subscribe_topic     => "stat/my_device/POWER1",
                                         );

or explicit definitions with no defaults

    my $outlet = Power::Outlet::MQTT->new(
                                          host                => "mqtt",
                                          publish_on          => "cmnd/my_device/POWER1+ON", #plus sign delimited topic and message
                                          publish_off         => "cmnd/my_device/POWER1+OFF",
                                          publish_switch      => "cmnd/my_device/POWER1+TOGGLE",
                                          publish_query       => "cmnd/my_device/POWER1+",
                                          subscribe_topic     => "stat/my_device/POWER1",
                                          subscribe_value_on  => 'ON'  #or qr/\A(?:ON|1)\Z/i,
                                          subscribe_value_off => 'OFF, #or qr/\A(?:OFF|0)\Z/i,
                                         );
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::MQTT is a package for controlling and querying an outlet or relay via MQTT

Examples:

    $ mosquitto_pub -h mqtt -t "cmnd/my_device/POWER1" -m ON
    $ mosquitto_pub -h mqtt -t "cmnd/my_device/POWER1" -m OFF
    $ mosquitto_sub -h mqtt -t "stat/my_device/POWER1" -v

## USAGE

    use Power::Outlet::MQTT;
    my $outlet = Power::Outlet::MQTT->new(host=>"mqtt", device=>"my_device");
    print $outlet->on, "\n";

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"MQTT", host=>"mqtt");
    my $outlet = Power::Outlet::MQTT->new(host=>"mqtt");

## PROPERTIES

### host

Sets and returns the host name of the MQTT broker.

Default: mqtt

### port

Sets and returns the port number of the MQTT broker.

Default: 1883

### secure

Sets and returns a boolean property to use secure MQTT protocol or not.

Default: if port=8883 then 1 else 0

### device

Sets and returns the device name of the MQTT topic.

Note: Only used when topics are autogenerated for devices that support the Tasmota MQTT topic conventions.

### relay

Sets and returns the relay of the device.  Only used when name is used to define default publish and subscribe topics.

Default: POWER1

### publish\_topic

MQTT topic to publish to control the relay

Default: "cmnd/$device/$relay"

### publish\_on

MQTT topic and message payload to publish to turn the relay on (plus sign delimited)

Default: "cmnd/$device/$relay+ON"

### publish\_off

MQTT topic and message payload to turn the relay off (plus sign delimited)

Default: "cmnd/$device/$relay+OFF"

### publish\_switch

MQTT topic and message payload to toggle the relay (plus sign delimited)

Default: "cmnd/$device/$relay+TOGGLE"

### publish\_query

MQTT topic and message payload to request the turn the current state of the relay (plus sign delimited)

Default: "cmnd/$device/$relay+"

### subscribe\_topic

MQTT topic which indicates the current state of the relay

Default: "stat/$device/$relay+"

### subscribe\_value\_on

MQTT message payload to indicate the current state of the relay as on

Default: "ON" or 1

### subscribe\_value\_off

MQTT message payload to indicate the current state of the relay as off

Default: "OFF" or 0

### user

Sets and returns the authentication user for the MQTT broker.

Default: undef

### password

Sets and returns the password used for authentication with the MQTT broker

Default: ""

## METHODS

### name

Sets and returns a user friendly name of this device relay.

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

### cycle

## ACCESSORS

### mqtt

Returns a cached connected [Net::MQTT::Simple](https://metacpan.org/pod/Net::MQTT::Simple) or [Net::MQTT::Simple::SSL](https://metacpan.org/pod/Net::MQTT::Simple::SSL) object.

## BUGS

Please log on GitHub

## AUTHOR

    Michael R. Davis

## COPYRIGHT

Copyright (c) 2023 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

# File: lib/Power/Outlet/Shelly.pm

## NAME

Power::Outlet::Shelly - Control and query a Shelly GIPO Relay with HTTP REST API

## SYNOPSIS

    my $outlet = Power::Outlet::Shelly->new(host=>"shelly", index=>0);
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";
    print $outlet->switch, "\n";
    print $outlet->cycle, "\n";

## DESCRIPTION

Power::Outlet::Shelly is a package for controlling and querying a relay index on Shelly hardware.

From: [https://shelly-api-docs.shelly.cloud/](https://shelly-api-docs.shelly.cloud/)

Commands can be executed via web (HTTP) requests, for example:

    http://<ip>/relay/0?turn=on
    http://<ip>/relay/0?turn=off
    http://<ip>/relay/0?turn=toggle
    http://<ip>/relay/0?timer=5

## USAGE

    use Power::Outlet::Shelly;
    my $outlet = Power::Outlet::Shelly->new(host=>"sw-kitchen", style=>"relay", index=>0);
    print $outlet->on, "\n";

Command Line

    $ power-outlet Shelly ON host sw-kitchen style relay index 0

Command Line (from settings)

    $ cat /etc/power-outlet.ini

    [Kitchen]
    type=Shelly
    name=Kitchen
    host=sw-kitchen
    style=relay
    index=0
    groups=Inside Lights
    groups=Main Floor


    $ power-outlet Config ON section Kitchen
    $ curl http://127.0.0.1/cgi-bin/power-outlet-json.cgi?name=Kitchen;action=ON

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"Shelly", host=>"shelly", index=>0);
    my $outlet = Power::Outlet::Shelly->new(host=>"shelly", index=>0);

## PROPERTIES

### style

Set the style to support "relay" (1, 1L, 2.5, 4, Plug, Uni, EM, 3EM), "light" (Dimmer, Bulb, Vintage, Duo), "color" (RGB Color), or "white" (RGB White)

    my $style = $outlet->style;
    my $style = $outlet->style('light');

default: relay

### index

Shelly hardware supports zero or more relay indexes starting at 0.

Default: 0

### host

Sets and returns the hostname or IP address.

Default: shelly

### port

Sets and returns the port number.

Default: 80

## METHODS

### name

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

Sends a message to the device to toggle the power

### cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

### cycle\_duration

Default; 10 seconds (floating point number)

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[https://shelly-api-docs.shelly.cloud/](https://shelly-api-docs.shelly.cloud/)

# File: lib/Power/Outlet/SonoffDiy.pm

## NAME

Power::Outlet::SonoffDiy - Control and query a Sonoff DIY device

## SYNOPSIS

    my $outlet = Power::Outlet::SonoffDiy->new(host => "SonoffDiy");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::SonoffDiy is a package for controlling and querying Sonoff ESP8266 hardware running Sonoff firmware in DIY mode.  This package supports and has been tested on both the version 1.4 (firmware 3.3.0) and version 2.0 (firmware 3.6.0) of the API.

From: [https://github.com/itead/Sonoff\_Devices\_DIY\_Tools](https://github.com/itead/Sonoff_Devices_DIY_Tools)

Commands can be executed via HTTP POST requests, for example:

    curl -i -XPOST -d '{"deviceid":"","data":{}}' http://10.10.7.1:8081/zeroconf/info

1.4 Return where data is a string

    {
      "seq"   : 21,
      "error" : 0,
      "data"  : "{\"switch\":\"off\",\"startup\":\"stay\",\"pulse\":\"off\",\"pulseWidth\":500,\"ssid\":\"my_ssid\",\"otaUnlock\":false}"
    }

2.0 Return where data is an object

    {
      "seq"   : 12,
      "error" : 0,
      "data":{
        "switch"         : "on",
        "startup"        : "stay",
        "pulse"          : "off",
        "pulseWidth"     : 500,
        "ssid"           : "my_ssid",
        "otaUnlock"      : false,
        "fwVersion"      : "3.6.0",
        "deviceid"       : "1001262ec1",
        "bssid"          : "fc:ec:da:81:c:98",
        "signalStrength" : -61
      }
    }

    curl -i -XPOST -d '{"deviceid":"","data":{"switch":"off"}}' http://10.10.7.1:8081/zeroconf/switch
    {
     "seq"   : 22,
     "error" : 0
    }

    curl -i -XPOST -d '{"deviceid":"","data":{"switch":"on"}}' http://10.10.7.1:8081/zeroconf/switch
    {
     "seq"   : 23,
     "error" : 0
    }

## USAGE

    use Power::Outlet::SonoffDiy;
    my $outlet = Power::Outlet::SonoffDiy->new(host=>"SonoffDiy");
    print $outlet->on, "\n";

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"SonoffDiy", host=>"SonoffDiy");
    my $outlet = Power::Outlet::SonoffDiy->new(host=>"SonoffDiy");

## PROPERTIES

### host

Sets and returns the hostname or IP address.

Default: SonoffDiy

### port

Sets and returns the port number.

Default: 8081

### http\_path

Sets and returns the http\_path.

Default: /

## METHODS

### name

Returns the name as configured.

Note: The Sonoff DIY firmware does not support setting a hostname or friendly name.

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

Sends a message to the device to toggle the power

### cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[https://github.com/itead/Sonoff\_Devices\_DIY\_Tools](https://github.com/itead/Sonoff_Devices_DIY_Tools)

# File: lib/Power/Outlet/Tasmota.pm

## NAME

Power::Outlet::Tasmota - Control and query a Tasmota GIPO configured as a Relay (Switch or Button)

## SYNOPSIS

    my $outlet = Power::Outlet::Tasmota->new(host => "tasmota", relay => "POWER1");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::Tasmota is a package for controlling and querying a relay on Tasmota ESP8266 hardware.

From: [https://tasmota.github.io/docs/#/Commands](https://tasmota.github.io/docs/#/Commands)

Commands can be executed via web (HTTP) requests, for example:

    http://<ip>/cm?cmnd=Power%20TOGGLE
    http://<ip>/cm?cmnd=Power%20On
    http://<ip>/cm?cmnd=Power%20off
    http://<ip>/cm?user=admin&password=joker&cmnd=Power%20Toggle

Examples:

Query default relay

    $ curl http://tasmota/cm?cmnd=POWER1
    {"POWER1":"ON"}

Toggle (Switch) relay 4

    $ curl http://tasmota/cm?user=foo;password=bar;cmnd=POWER4+TOGGLE
    {"POWER4":"OFF"}

Turn ON relay 2

    $ curl http://tasmota/cm?user=foo;password=bar;cmnd=POWER2+ON
    {"POWER2":"ON"}

## USAGE

    use Power::Outlet::Tasmota;
    my $relay = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER2");
    print $relay->on, "\n";

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"Tasmota", host=>"tasmota", relay=>"POWER2");
    my $outlet = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER2");

## PROPERTIES

### relay

Tasmota version 8.1.0 supports up to 8 relays.  These 8 relays map to the relay tokens "POWER1", "POWER2", ... "POWER8". With "POWER" being the default relay name for the first relay defined in the configuration.

Default: POWER1

### host

Sets and returns the hostname or IP address.

Default: tasmota

### port

Sets and returns the port number.

Default: 80

### http\_path

Sets and returns the http\_path.

Default: /cm

### user

Sets and returns the user used for authentication with the Tasmota hardware

    my $outlet = Power::Outlet::Tasmota->new(host=>"tasmota", relay=>"POWER1", user=>"mylogin", password=>"mypassword");
    print $outlet->query, "\n";

Default: undef() #which is only passed on the url when defined

### password

Sets and returns the password used for authentication with the Tasmota hardware

Default: "" #which is only passed on the url when user property is defined

## METHODS

### name

Returns the FriendlyName from the Tasmota hardware.

Note: The FriendlyName is cached for the life of the object.

### query

Sends an HTTP message to the device to query the current state

### on

Sends a message to the device to Turn Power ON

### off

Sends a message to the device to Turn Power OFF

### switch

Sends a message to the device to toggle the power

### cycle

Sends messages to the device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[https://tasmota.github.io/docs/#/Commands](https://tasmota.github.io/docs/#/Commands)

# File: lib/Power/Outlet/TuyaAPI.pm

## NAME

Power::Outlet::TuyaAPI - Control and query an outlet via the TuyaAPI.

## SYNOPSIS

    my $outlet = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::TuyaAPI is a package for controlling and querying an outlet via the TuyaAPI.

This package is a wrapper around [WebService::Tuya::IoT::API](https://metacpan.org/pod/WebService::Tuya::IoT::API) please see that documentation for device configuration.

## USAGE

    use Power::Outlet::TuyaAPI;
    my $relay = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
    print $relay->on, "\n";

## CONSTRUCTOR

### new

    my $outlet = Power::Outlet->new(type=>"TuyaAPI", client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");
    my $outlet = Power::Outlet::TuyaAPI->new(client_id=>"abc123", client_secret=>"cde234", deviceid=>"def345", switch=>"switch_1");

## PROPERTIES

### host 

default: openapi.tuyaus.com

### client\_id

The Client ID found on https://iot.tuya.com/ project overview page.

### client\_secret

The Client Secret found on https://iot.tuya.com/ project overview page.

### deviceid

The Device ID found on https://iot.tuya.com/ project devices page.

### relay

The relay name or "code" for a particular relay on the device.  Devices with a single relay this value will most likely be switch\_1 but, for devices with multiple relays the first relay is normally switch\_1 and subsequent relays should be labeled switch\_2, etc.

default: switch\_1

## METHODS

### name

Returns the name from the device information API

Note: The name is cached for the life of the object.

### query

Sends an HTTP message to the API to query the current state of the device relay

### on

Sends a message to the API to turn the device relay ON

### off

Sends a message to the API to turn the device relay OFF

### switch

Sends a message to the API to toggle the device relay state

### cycle

Sends messages to the device to cycle the device relay state

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

## SEE ALSO

[https://tasmota.github.io/docs/#/Commands](https://tasmota.github.io/docs/#/Commands)

# File: lib/Power/Outlet/WeMo.pm

## NAME

Power::Outlet::WeMo - Control and query a Belkin WeMo power outlet

## SYNOPSIS

    my $outlet=Power::Outlet::WeMo->new(host => "mywemo");
    print $outlet->query, "\n";
    print $outlet->on, "\n";
    print $outlet->off, "\n";

## DESCRIPTION

Power::Outlet::WeMo is a package for controlling and querying an outlet on a Belkin WeMo network attached power outlet.

## USAGE

    use Power::Outlet::WeMo;
    use DateTime;
    my $lamp=Power::Outlet::WeMo->new(host=>"mywemo");
    my $hour=DateTime->now->hour;
    my $night=$hour > 20 ? 1 : $hour < 06 ? 1 : 0;
    if ($night) {
      print $lamp->on, "\n";
    } else {
      print $lamp->off, "\n";
    }

## CONSTRUCTOR

### new

    my $outlet=Power::Outlet->new(type=>"WeMo", "host=>"mywemo");
    my $outlet=Power::Outlet::WeMo->new(host=>"mywemo");

## PROPERTIES

### host

Sets and returns the hostname or IP address.

Note: Set IP address via DHCP static mapping

### port

Sets and returns the port number.

### name

Returns the configured FriendlyName from the WeMo device

## METHODS

### query

Sends a UPnP message to the WeMo device to query the current state

### on

Sends a UPnP message to the WeMo device to Turn Power ON

### off

Sends a UPnP message to the WeMo device to Turn Power OFF

### switch

Queries the device for the current status and then requests the opposite.

### cycle

Sends UPnP messages to the WeMo device to Cycle Power (ON-OFF-ON or OFF-ON-OFF).

## BUGS

Please log on RT and send an email to the author.

## SUPPORT

DavisNetworks.com supports all Perl applications including this package.

## AUTHOR

    Michael R. Davis
    CPAN ID: MRDVT
    DavisNetworks.com

## COPYRIGHT

Copyright (c) 2013 Michael R. Davis

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

Portions of the WeMo Implementation Copyright (c) 2013 Eric Blue

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## SEE ALSO

[WebService::Belkin::Wemo::Device](https://metacpan.org/pod/WebService::Belkin::Wemo::Device), [https://gist.github.com/jscrane/7257511](https://gist.github.com/jscrane/7257511)

# File: scripts/power-outlet

## NAME

power-outlet - Control and query a Power::Outlet device from command line

## SYNOPSIS

    power-outlet -v
    power-outlet WeMo          ON   host mywemo
    power-outlet WeMo          OFF  host mywemo
    power-outlet iBoot         ON   host mylamp
    power-outlet iBoot         OFF  host mylamp
    power-outlet iBootBar      ON   host mybar   outlet  1
    power-outlet iBootBar      OFF  host mybar   outlet  1
    power-outlet iBootBarGroup ON   host mybar   outlets 1,2,3,4
    power-outlet iBootBarGroup OFF  host mybar   outlets 1,2,3,4

## DESCRIPTION

This script provide a command line interface for Power::Outlet devices

## COPYRIGHT

Copyright (c) 2013 Michael R. Davis <mrdvt92>

## LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

# File: scripts/power-outlet.cgi

## NAME

power-outlet.cgi - Control multiple Power::Outlet devices from web browser

## DESCRIPTION

power-outlet.cgi is a CGI application to control multiple Power::Outlet devices.  It was written to work on iPhone and look ok in most browsers.

## CONFIGURATION

To add an outlet for the CGI application, add a new INI section to the power-outlet.ini file.

    [Unique_Section_Name]
    type=iBoot
    host=Lamp
    groups=Inside
    groups=Kitchen

If you need to override the defaults

    [Unique_Section_Name]
    type=iBoot
    host=Lamp
    port=80
    pass=PASS
    name=My iBoot Description
    groups=Outside
    groups=Deck

WeMo device

    [WeMo]
    type=WeMo
    host=mywemo
    groups=Inside
    groups=Study

Default Location: /usr/share/power-outlet/conf/power-outlet.ini

## BUILD

    rpmbuild -ta Power-Outlet-*.tar.gz

## INSTALLATION

I recommend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet and configures Apache with /etc/httpd/conf.d/power-outlet.conf.

    sudo yum install perl-Power-Outlet-application-cgi

# File: scripts/power-outlet-json.cgi

## NAME

power-outlet-json.cgi - Control Power::Outlet device with JSON web service (e.g. Node-Red)

## DESCRIPTION

power-outlet-json.cgi is a CGI application to control a Power::Outlet device with a web service.

## API

The script is called over HTTP with name and action parameters.  The name is the Section Name from the INI file and the action is one of on, off, query, or switch.

    http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=off
    http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=on
    http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=query
    http://localhost/power-outlet/power-outlet-json.cgi?name=Lamp;action=switch

Return is a JSON hash with keys status and state.  status is OK if there are no errors, state is the state of the switch after command either ON or OFF.

    {"status":"OK","state":"ON"}

## Node-Red Integration

Use three nodes: inject, http request, and debug.

- In the inject node
    - Set the "Topic" to the desired INI config file \[section\] name.
    - Set the "Payload" to one of "ON", "OFF", "QUERY" or "SWITCH"
- In the http request node
    - Set the "Method" to GET (script also supports POST)
    - Set the "URL" to https://127.0.0.1/power-outlet/power-outlet-json.cgi?name={{topic}};action={{payload}}
    - Set the "Return" to a parsed JSON Object
- In the debug node
    - Set the "Output" to msg.payload.state which returns "ON" or "OFF"

### Node Red Example

    [{"id":"736cc2df.cc616c","type":"inject","z":"bbbcee28.8891c","name":"","topic":"Christmas Tree","payload":"On","payloadType":"str","repeat":"","crontab":"","once":false,"onceDelay":0.1,"x":330,"y":1480,"wires":[["6f024760.ea5058"]]},{"id":"6f024760.ea5058","type":"http request","z":"bbbcee28.8891c","name":"power-outlet-json.cgi","method":"GET","ret":"obj","paytoqs":false,"url":"https://127.0.0.1/power-outlet/power-outlet-json.cgi?name={{topic}};action={{payload}}","tls":"","persist":false,"proxy":"","authType":"","x":560,"y":1480,"wires":[["2673faca.21f8d6"]],"inputLabels":["Topic=>name, Payload=>action"]},{"id":"2673faca.21f8d6","type":"debug","z":"bbbcee28.8891c","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload.state","targetType":"msg","x":790,"y":1480,"wires":[]}]

## CONFIGURATION

To add an outlet for the web service, add a new INI section to the power-outlet.ini file.

    [Tree]
    type=Tasmota
    host=light-tree
    groups=Outside Lights

If you need to override the defaults

    [Kitchen]
    type=Shelly
    name=Kitchen
    host=sw-kitchen
    port=80
    style=relay
    index=0
    groups=Inside Lights

WeMo device

    [Living Room]
    type=WeMo
    host=sw-living-room
    groups=Inside Lights

Default Location: /etc/power-outlet.ini

### BUILD

    rpmbuild -ta Power-Outlet-*.tar.gz

## INSTALLATION

I recommend installation with the provided RPM package perl-Power-Outlet-application-cgi which installs to /usr/share/power-outlet.

    sudo yum install perl-Power-Outlet-application-cgi

# File: scripts/power-outlet-mqtt-listener.pl

## NAME

power-outlet-mqtt-listener.pl - MQTT listener to control Power::Outlet devices

## SYNOPSIS

    power-outlet-mqtt-listener.pl [-c /etc/power-outlet-mqtt-listener.yml]

## DESCRIPTION

This script provides an MQTT listener to control Power::Outlet devices

## CONFIGURATION

The YAML formatted file /etc/power-outlet-mqtt-listener.yml is a key-value hash.  

The "host" key value is a string representing the host name of the MQTT server.

The "directives" key value is a list of individual directives with "name", "topic", "value" (topic payload to match) and "actions".

The "actions" key value is a list of individual actions to run when "topic" and "value" match. Individual actions have keys "name", "driver", "command", and "options". "options" is a hash of options that is passed to the driver.

Example:

    ---
    host: mqtt

    directives:

    - name: Smart Outlet Top Button Press
      topic: cmnd/smartoutlet_button_topic/POWER1
      value: TOGGLE
      actions:
      - name: Outside Lights
        driver: iBootBarGroup
        command: 'ON'
        options:
          outlets: '1,2,6,7'
          host: bar

    - name: Smart Outlet Bottom Button Press
      topic: cmnd/smartoutlet_button_topic/POWER2
      value: TOGGLE
      actions:
      - name: Outside Lights
        driver: iBootBarGroup
        command: 'OFF'
        options:
          outlets: '1,2,6,7'
          host: bar

## SYSTEMD

The included rpm spec file installs a systemd service file so you can run this process from systemd.

    systemctl power-outlet-mqtt-listener.service enable
    systemctl power-outlet-mqtt-listener.service start

## BUILD

    rpmbuild -ta Power-Outlet-*.tar.gz

## INSTALL

    sudo yum install perl-Power-Outlet-mqtt-listener 

## COPYRIGHT

Copyright (c) 2020 Michael R. Davis <mrdvt92>

## LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

