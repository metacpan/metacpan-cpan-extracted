# the mom.20050304 data joined and put into an array
@data = (
q{03/04/2005 11:27:18 | 0002 | pbs_mom | Svr | Log | Log opened},
q{03/04/2005 11:27:18 | 0100 | pbs_mom | Req |  | Type 1 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18 | 0100 | pbs_mom | Req |  | Type 3 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18 | 0100 | pbs_mom | Req |  | Type 4 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18 | 0100 | pbs_mom | Req |  | Type 5 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18 | 0008 | pbs_mom | Job | 46.davinci | Started, pid = 7394},
q{03/04/2005 11:27:19 | 0080 | pbs_mom | Job | 46.davinci | task 1 terminated},
q{03/04/2005 11:27:19 | 0008 | pbs_mom | Job | 46.davinci | Terminated},
q{03/04/2005 11:27:19 | 0008 | pbs_mom | Job | 46.davinci | kill_job},
q{03/04/2005 11:27:20 | 0100 | pbs_mom | Job | 46.davinci | Obit sent},
q{03/04/2005 11:27:20 | 0100 | pbs_mom | Req |  | Type 54 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:20 | 0100 | pbs_mom | Req |  | Type 6 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/05/2005 18:05:20 | 0002 | pbs_mom | Svr | Log | Log closed}
);
@records = (
q{03/04/2005 11:27:18;0002;pbs_mom;Svr;Log;Log opened},
q{03/04/2005 11:27:18;0100;pbs_mom;Req;;Type 1 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18;0100;pbs_mom;Req;;Type 3 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18;0100;pbs_mom;Req;;Type 4 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18;0100;pbs_mom;Req;;Type 5 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:18;0008;pbs_mom;Job;46.davinci;Started, pid = 7394},
q{03/04/2005 11:27:19;0080;pbs_mom;Job;46.davinci;task 1 terminated},
q{03/04/2005 11:27:19;0008;pbs_mom;Job;46.davinci;Terminated},
q{03/04/2005 11:27:19;0008;pbs_mom;Job;46.davinci;kill_job},
q{03/04/2005 11:27:20;0100;pbs_mom;Job;46.davinci;Obit sent},
q{03/04/2005 11:27:20;0100;pbs_mom;Req;;Type 54 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/04/2005 11:27:20;0100;pbs_mom;Req;;Type 6 request received from PBS_Server@davinci.nersc.gov, sock=10},
q{03/05/2005 18:05:20;0002;pbs_mom;Svr;Log;Log closed});
