# rpctiny rpcswitch example tests
#
RPC_SWITCH = rpc-switch
RPC_SWITCH_GIT = https://github.com/a6502/$(RPC_SWITCH).git
RPCTINY = perl -I../../lib ../rpctiny
WHO = theEmployee

all: $(RPC_SWITCH) $(RPC_SWITCH)/rpcswitch.crt $(RPC_SWITCH)/etc/config.pl

tests: test-ping test-worker

clobber:
	-rm -rf $(RPC_SWITCH)

perl516compat:
	perl -pi -e 's/^(use List::Util.*)/#$$1/' $(RPC_SWITCH)/lib/RPC/Switch/Auth/ClientCert.pm
	perl -pi -e 's/ any / grep /' $(RPC_SWITCH)/lib/RPC/Switch/Auth/ClientCert.pm

fixtlsauth:
	(cd $(RPC_SWITCH) && patch -p1 -b -i ../patches/0001-fix-tls-verify-clientauth.patch)

$(RPC_SWITCH):
	git clone $(RPC_SWITCH_GIT)
	make perl516compat
	make fixtlsauth

$(RPC_SWITCH)/etc/config.pl:
	cp $(RPC_SWITCH)/etc/config.pl.example $(RPC_SWITCH)/etc/config.pl
	cp $(RPC_SWITCH)/etc/methods.pl.example $(RPC_SWITCH)/etc/methods.pl
	touch $(RPC_SWITCH)/etc/switch.passwd
	echo "example.com:$(WHO)" > $(RPC_SWITCH)/etc/switch.cnfile

$(RPC_SWITCH)/rpcswitch.crt:
	openssl req -x509 -nodes -newkey rsa:2048 -keyout $(RPC_SWITCH)/rpcswitch.pem -out $(RPC_SWITCH)/rpcswitch.crt -subj "/C=DE/O=Acme/OU=TestDept/CN=localhost/emailAddress=rpcswitch@localhost"
	openssl req -x509 -nodes -newkey rsa:2048 -keyout $(RPC_SWITCH)/rpcclient.pem -out $(RPC_SWITCH)/rpcclient.crt -subj "/C=DE/O=Acme/OU=TestDept/CN=example.com/emailAddress=test@example.com"
	openssl x509 -in $(RPC_SWITCH)/rpcclient.crt -noout -subject -dates
	ln -s rpcclient.crt $(RPC_SWITCH)/myCA.crt

test-ping:
	(cd $(RPC_SWITCH) && ./bin/rpcswitch &)
	sleep 1;
	-(cd $(RPC_SWITCH) && $(RPCTINY) -H 127.0.0.1:6850 -S -C rpcclient.crt -K rpcclient.pem -V rpcswitch.crt -l $(WHO))
	pkill -f ./bin/rpcswitch

test-worker:
	(cd $(RPC_SWITCH) && ./bin/rpcswitch &)
	sleep 1;
	-(cd $(RPC_SWITCH) && $(RPCTINY) -H 127.0.0.1:6850 -S -C rpcclient.crt -K rpcclient.pem -l $(WHO) -m bar.add -w '{ my ($$params) = @_; return {msg => "bar.add got $$params->{val}"}}' &)
	sleep 1;
	-(cd $(RPC_SWITCH) && $(RPCTINY) -H 127.0.0.1:6850 -S -C rpcclient.crt -K rpcclient.pem -l $(WHO) -m foo.add -j '{val => 123}')
	pkill -f ./bin/rpcswitch
	pkill -f ./rpctiny

