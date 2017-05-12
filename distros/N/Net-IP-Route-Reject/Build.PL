use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    ( module_name     => 'Net::IP::Route::Reject',
      license         => 'artistic',
	requires => {
	'IPC::Cmd' =>'0.04'
	}
    )->create_build_script;
