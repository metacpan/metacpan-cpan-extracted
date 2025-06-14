#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#include <time.h>

#define WALL '#'
#define PATH ' '
#define START 'S'
#define END 'E'
#define PLAYER '@'

static int hv_get_int(HV *hv, const char *key) {
	SV **svp = hv_fetch(hv, key, strlen(key), 0);
	return svp ? SvIV(*svp) : 0;
}

static char* av_get_str(AV *av, int index) {
	SV **svp = av_fetch(av, index, 0);
	return svp ? SvPV_nolen(*svp) : NULL;
}

static void hv_set_int(HV *hv, const char *key, int val) {
	hv_store(hv, key, strlen(key), newSViv(val), 0);
}

static AV* hv_get_av(HV *hv, const char *key) {
	SV **svp = hv_fetch(hv, key, strlen(key), 0);
	return (svp && SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) ? (AV*)SvRV(*svp) : NULL;
}

static void hv_set_av(HV *hv, const char *key, AV *av) {
	hv_store(hv, key, strlen(key), newRV_noinc((SV*)av), 0);
}

static void carve(HV *hv, int x, int y) {
	int width = hv_get_int(hv, "width");
	int height = hv_get_int(hv, "height");
	AV *maze = hv_get_av(hv, "maze");
	int dirs[4][2] = { {0,-1}, {1,0}, {0,1}, {-1,0} };
	for (int i = 0; i < 4; ++i) {
		int j = rand() % 4;
		int tmp0 = dirs[i][0], tmp1 = dirs[i][1];
		dirs[i][0] = dirs[j][0];
		dirs[i][1] = dirs[j][1];
		dirs[j][0] = tmp0;
		dirs[j][1] = tmp1;
	}
	char *row = av_get_str(maze, y);
	row[x] = PATH;
	for (int i = 0; i < 4; ++i) {
		int dx = dirs[i][0], dy = dirs[i][1];
		int nx = x + 2*dx, ny = y + 2*dy;
		if (nx > 0 && nx < width-1 && ny > 0 && ny < height-1) {
			char *nrow = av_get_str(maze, ny);
			if (nrow[nx] == WALL) {
				char *midrow = av_get_str(maze, y+dy);
				midrow[x+dx] = PATH;
				carve(hv, nx, ny);
			}
		}
	}
}

MODULE = Term::Maze  PACKAGE = Term::Maze  PREFIX = maze_

SV*
maze_new(class, width_in, height_in)
	char *class
	int width_in
	int height_in
PREINIT:
	HV *hv;
	AV *maze;
	int width, height, i, j;
CODE:
	width = (width_in % 2 == 0) ? width_in+1 : width_in;
	height = (height_in % 2 == 0) ? height_in+1 : height_in;
	hv = newHV();
	maze = newAV();
	for (i = 0; i < height; ++i) {
		SV *row = newSVpv("", width);
		SvGROW(row, width+1);
		char *s = SvPV_nolen(row);
		for (j = 0; j < width; ++j)
			s[j] = WALL;
		s[width] = '\0';
		SvCUR_set(row, width);
		av_push(maze, row);
	}
	hv_set_int(hv, "width", width);
	hv_set_int(hv, "height", height);
	hv_set_int(hv, "px", 1);
	hv_set_int(hv, "py", 1);
	hv_set_av(hv, "maze", maze);
	carve(hv, 1, 1);
	char *start_row = av_get_str(maze, 1);
	if (start_row) start_row[1] = START;
	char *end_row = av_get_str(maze, height-2);
	if (end_row) end_row[width-2] = END;
	RETVAL = sv_bless(newRV_noinc((SV*)hv), gv_stashpv(class, GV_ADD));
OUTPUT:
	RETVAL

void
maze_move_player(self, direction)
	SV *self
	char direction
PREINIT:
	HV *hv;
	int dx = 0, dy = 0;
	int nx, ny, width, height;
	AV *maze;
CODE:
	hv = (HV*)SvRV(self);
	int px = hv_get_int(hv, "px");
	int py = hv_get_int(hv, "py");
	width = hv_get_int(hv, "width");
	height = hv_get_int(hv, "height");
	maze = hv_get_av(hv, "maze");
	switch (direction) {
		case 'w': dy = -1; break;
		case 'a': dx = -1; break;
		case 's': dy = 1; break;
		case 'd': dx = 1; break;
		default: XSRETURN_EMPTY;
	}
	nx = px + dx;
	ny = py + dy;
	if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
		SV **svp = av_fetch(maze, ny, 0);
		if (svp) {
			char *row = SvPV_nolen(*svp);
			if (row[nx] != WALL) {
				hv_set_int(hv, "px", nx);
				hv_set_int(hv, "py", ny);
			}
		}
	}

AV *
maze_get_maze_with_player(self)
	SV *self
PREINIT:
	HV *hv;
	int i, j, width, height, px, py;
	AV *maze, *rows;
	char *row, *src;
CODE:
	hv = (HV*)SvRV(self);
	width = hv_get_int(hv, "width");
	height = hv_get_int(hv, "height");
	px = hv_get_int(hv, "px");
	py = hv_get_int(hv, "py");
	maze = hv_get_av(hv, "maze");
	rows = newAV();
	for (i = 0; i < height; ++i) {
		SV **svp = av_fetch(maze, i, 0);
		src = svp ? SvPV_nolen(*svp) : NULL;
		row = (char *)malloc(width * 16 + 1);
		int pos = 0;
		for (j = 0; j < width; ++j) {
			if (i == py && j == px) {
				pos += sprintf(row + pos, "\033[34m%c\033[0m", PLAYER);
			} else if (src && src[j] == WALL) {
				pos += sprintf(row + pos, "\033[31m%c\033[0m", WALL);
			} else if (src && (src[j] == START || src[j] == END)) {
				pos += sprintf(row + pos, "\033[32m%c\033[0m", src[j]);
			} else if (src) {
				row[pos++] = src[j];
			} else {
				row[pos++] = ' ';
			}
		}
		row[pos] = '\0';
		av_push(rows, newSVpv(row, 0));
		free(row);
	}
	RETVAL = rows;
OUTPUT:
	RETVAL

int
maze_at_exit(self)
	SV *self
PREINIT:
	HV *hv;
	int px, py;
	AV *maze;
	int width, height;
CODE:
	hv = (HV*)SvRV(self);
	px = hv_get_int(hv, "px");
	py = hv_get_int(hv, "py");
	maze = hv_get_av(hv, "maze");
	width = hv_get_int(hv, "width");
	height = hv_get_int(hv, "height");
	if (maze && py >= 0 && py < height) {
		SV **svp = av_fetch(maze, py, 0);
		if (svp) {
			char *row = SvPV_nolen(*svp);
			RETVAL = (row[px] == END);
		} else {
			RETVAL = 0;
		}
	} else {
		RETVAL = 0;
	}
OUTPUT:
	RETVAL