# start from nothing but vagrant
# http://www.vagrantup.com/downloads

vagrant plugin install vagrant-vbox-snapshot 

vagrant global-status | \
	perl -MCwd -e '
		$d=getcwd; 
		while(<STDIN>){
			next unless /^[a-f0-9]/../^\s/; 
			next unless /\S/; 
			@F=split;
			next unless $F[-1] eq $d;
			print qq($F[0]\n);
			}' | \
	xargs vagrant destroy --force

vagrant box remove --force ubuntu/trusty64 
vagrant global-status --prune
vagrant box add ubuntu/trusty64 https://atlas.hashicorp.com/ubuntu/boxes/trusty64
vagrant up
vagrant snapshot take first
