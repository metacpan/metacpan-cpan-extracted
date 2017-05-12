# QBit-WebInterface-PSGI

### nano ./lib/WebInterface.pm
        use base qw(QBit::WebInterface::PSGI Application);

### nano ./bin/starter.pl
        #!/usr/bin/perl 

        use qbit; 

        use lib qw(./lib);

        use WebInterface;

        WebInterface->new()->run;
        
### start

        starman ./bin/starter.pl
