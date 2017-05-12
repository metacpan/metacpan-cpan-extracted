use inc::Module::Install;

RTx 'RTx-TicketlistTransactions';

repository 'https://github.com/bestpractical/rtx-ticketlisttransactions';

requires_rt '4.0.0';
rt_too_new '4.4.0';

sign;
WriteAll;
