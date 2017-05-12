%#define YP_SOCKNAME	"/var/run/yppasswdsock"

struct x_master_passwd {
	string pw_name<>;	
	string pw_passwd<>;	
	int pw_uid;		
	int pw_gid;		
        string pw_age<>;
        string pw_comment<>;
	string pw_gecos<>;	
	string pw_dir<>;	
	string pw_shell<>;	
};

const _YPMAXDOMAIN = 64;

struct master_yppasswd {
	string oldpass<>;		
	x_master_passwd newpw;		
};


program MASTER_YPPASSWDPROG {
	version MASTER_YPPASSWDVERS {
		int
		YPPASSWDPROC_UPDATE_MASTER(master_yppasswd) = 1;
	} = 1;
} = 100009;
