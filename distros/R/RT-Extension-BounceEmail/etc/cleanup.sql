delete from templates where name = 'Bounce';

delete from scripactions where name = 'Send Bounce';

delete from scripconditions where name = 'On Bounce';

delete from scrips where template = 'Bounce' and description = 'Bounce Transaction';
