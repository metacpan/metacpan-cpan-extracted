INSERT INTO menus (menu, label, value, seclev, menuorder) VALUES ('gallery','Picture Groups','[% constants.rootdir %]/gallery.pl',0,1);
INSERT INTO menus (menu, label, value, seclev, menuorder) VALUES ('gallery','Create Picture Group','[% constants.rootdir %]/gallery.pl?op=edit_group',1000,2);
INSERT INTO menus (menu, label, value, seclev, menuorder) VALUES ('gallery','Render Pictures','[% constants.rootdir %]/gallery.pl?op=render_pictures',1000,3);
INSERT INTO menus (menu, label, value, seclev, menuorder) VALUES ('gallery','Add Pictures','[% constants.rootdir %]/gallery.pl?op=add_pictures',1000,4);
INSERT INTO menus (menu, label, value, seclev, menuorder) VALUES ('gallery','Find Unassigned Pictures','[% constants.rootdir %]/gallery.pl?op=find_unassigned_pictures',1000,5);

INSERT INTO gallery_sizes (size, width, height, jpegquality) VALUES ('thumb',    80,   60,  75);
INSERT INTO gallery_sizes (size, width, height, jpegquality) VALUES ('small',   320,  240,  75);
INSERT INTO gallery_sizes (size, width, height, jpegquality) VALUES ('medium',  640,  480,  75);
INSERT INTO gallery_sizes (size, width, height, jpegquality) VALUES ('large',  1024,  768,  75);
INSERT INTO gallery_sizes (size, width, height, jpegquality) VALUES ('big',    1280,  960,  75);

INSERT INTO vars (name, value, description) VALUES ('gallery_admin_seclev', 10000, 'Seclev for admins of Slash::Gallery');
INSERT INTO vars (name, value, description) VALUES ('gallery_max_size', 3, 'Default max size id of pictures user can view (see gallery_sizes)');
INSERT INTO vars (name, value, description) VALUES ('max_galleryview_viewings', 20, 'Default max reads over gallery_max_size per time period');
