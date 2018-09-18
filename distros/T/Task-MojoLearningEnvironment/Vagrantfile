Vagrant.configure(2) do |config|
	config.vm.box = "ubuntu/trusty64"

	config.vm.provider "virtualbox" do |v|
		v.memory = 1024
	end

	config.vm.network "forwarded_port", guest: 3000, host: 8080

	config.vm.synced_folder "./", "/home/vagrant/shared_files"

	config.vm.provision "shell", privileged: false, path: "vagrant-provision.sh"
end
