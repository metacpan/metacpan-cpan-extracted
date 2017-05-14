use OS2::UPM;

($name, $type) = OS2::UPM::local_user()
  or warn "local_user: ", OS2::UPM::message(OS2::UPM::error()), "\n";
print "local_user: name='$name' type='$type'\n";

($name, $type) = OS2::UPM::local_logon()
  or warn "local_logon: ", OS2::UPM::message(OS2::UPM::error()), "\n";
print "local_logon: name='$name' type='$type'\n";

@users = OS2::UPM::user_list("*", OS2::UPM_ALL)
  or warn "user_list: ", OS2::UPM::message(OS2::UPM::error()), "\n";
for ($i = 0; $i < @users; $i += 4) {
	($userid, $node, $type, $session) = splice(@users, 0, 4);
	print "userid=$userid, node=$node, type=$type, session=$session\n";
}

OS2::UPM::logoff_user($name)
  or warn "logoff_user: ", OS2::UPM::message(OS2::UPM::error()), "\n";

