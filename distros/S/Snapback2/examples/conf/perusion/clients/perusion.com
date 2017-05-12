<Backup perusion.com>
	Directory /home/arnow/
	Directory /home/buck/
	Directory /home/matt/
	Directory /home/mike/
	Directory /home/perusion/
	Directory /home/phsat/
	Directory /home/tag/
	Directory /home/value/
	<Directory /var/lib/mysql/>
		DestinationList /mnt/backup2 /mnt/backup4
		Monthlies 3
	</Directory>
	<Directory /var/lib/pgsql/>
		DestinationList /mnt/backup2 /mnt/backup4
		Monthlies 3
	</Directory>
</Backup>
