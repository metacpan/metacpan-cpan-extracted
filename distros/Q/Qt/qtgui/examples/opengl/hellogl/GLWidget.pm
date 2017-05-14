package GLWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GLWidget );
use List::Util qw(min);
use OpenGL;

# [1]
use QtCore4::slots
    setXRotation => ['int'],
    setYRotation => ['int'],
    setZRotation => ['int'];

use QtCore4::signals
    xRotationChanged => ['int'],
    yRotationChanged => ['int'],
    zRotationChanged => ['int'];
# [1]

sub object() {
    return this->{object};
}

sub xRot() {
    return this->{xRot};
}

sub yRot() {
    return this->{yRot};
}

sub zRot() {
    return this->{zRot};
}

sub lastPos() {
    return this->{lastPos};
}

sub trolltechGreen() {
    return this->{trolltechGreen};
}

sub trolltechPurple() {
    return this->{trolltechPurple};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{object} = 0;
    this->{xRot} = 0;
    this->{yRot} = 0;
    this->{zRot} = 0;

    this->{trolltechGreen} = Qt::Color::fromCmykF(0.40, 0.0, 1.0, 0.0);
    this->{trolltechPurple} = Qt::Color::fromCmykF(0.39, 0.39, 0.0, 0.0);
}
# [0]

# [1]
sub DESTROY
{
    this->makeCurrent();
    glDeleteLists(this->object, 1);
}
# [1]

# [2]
sub minimumSizeHint
{
    return Qt::Size(50, 50);
}
# [2]

# [3]
sub sizeHint
# [3] //! [4]
{
    return Qt::Size(400, 400);
}
# [4]

# [5]
sub setXRotation
{
    my ($angle) = @_;
    this->normalizeAngle(\$angle);
    if ($angle != this->xRot) {
        this->{xRot} = $angle;
        emit this->xRotationChanged($angle);
        this->updateGL();
    }
}
# [5]

sub setYRotation
{
    my ($angle) = @_;
    this->normalizeAngle(\$angle);
    if ($angle != this->yRot) {
        this->{yRot} = $angle;
        emit this->yRotationChanged($angle);
        this->updateGL();
    }
}

sub setZRotation
{
    my ($angle) = @_;
    this->normalizeAngle(\$angle);
    if ($angle != this->zRot) {
        this->{zRot} = $angle;
        emit this->zRotationChanged($angle);
        this->updateGL();
    }
}

# [6]
sub initializeGL
{
    this->qglClearColor(this->trolltechPurple->dark());
    this->{object} = this->makeObject();
    glShadeModel(GL_FLAT);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
}
# [6]

# [7]
sub paintGL
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glLoadIdentity();
    glTranslated(0.0, 0.0, -10.0);
    glRotated(this->xRot / 16.0, 1.0, 0.0, 0.0);
    glRotated(this->yRot / 16.0, 0.0, 1.0, 0.0);
    glRotated(this->zRot / 16.0, 0.0, 0.0, 1.0);
    glCallList(this->object);
}
# [7]

# [8]
sub resizeGL
{
    my ($width, $height) = @_;
    my $side = min($width, $height);
    glViewport(($width - $side) / 2, ($height - $side) / 2, $side, $side);

    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-0.5, +0.5, +0.5, -0.5, 4.0, 15.0);
    glMatrixMode(GL_MODELVIEW);
}
# [8]

# [9]
sub mousePressEvent
{
    my ($event) = @_;
    this->{lastPos} = $event->pos();
}
# [9]

# [10]
sub mouseMoveEvent
{
    my ($event) = @_;
    my $dx = $event->x() - this->lastPos->x();
    my $dy = $event->y() - this->lastPos->y();

    if ($event->buttons() & Qt::LeftButton()) {
        this->setXRotation(this->xRot + 8 * $dy);
        this->setYRotation(this->yRot + 8 * $dx);
    } elsif ($event->buttons() & Qt::RightButton()) {
        this->setXRotation(this->xRot + 8 * $dy);
        this->setZRotation(this->zRot + 8 * $dx);
    }
    this->{lastPos} = $event->pos();
}
# [10]

sub makeObject
{
    my $list = glGenLists(1);
    glNewList($list, GL_COMPILE);

    glBegin(GL_QUADS);

    my $x1 = +0.06;
    my $y1 = -0.14;
    my $x2 = +0.14;
    my $y2 = -0.06;
    my $x3 = +0.08;
    my $y3 = +0.00;
    my $x4 = +0.30;
    my $y4 = +0.22;

    this->quad($x1, $y1, $x2, $y2, $y2, $x2, $y1, $x1);
    this->quad($x3, $y3, $x4, $y4, $y4, $x4, $y3, $x3);

    this->extrude($x1, $y1, $x2, $y2);
    this->extrude($x2, $y2, $y2, $x2);
    this->extrude($y2, $x2, $y1, $x1);
    this->extrude($y1, $x1, $x1, $y1);
    this->extrude($x3, $y3, $x4, $y4);
    this->extrude($x4, $y4, $y4, $x4);
    this->extrude($y4, $x4, $y3, $x3);

    my $Pi = 3.14159265358979323846;
    my $NumSectors = 200;

    for (my $i = 0; $i < $NumSectors; ++$i) {
        my $angle1 = ($i * 2 * $Pi) / $NumSectors;
        my $x5 = 0.30 * sin($angle1);
        my $y5 = 0.30 * cos($angle1);
        my $x6 = 0.20 * sin($angle1);
        my $y6 = 0.20 * cos($angle1);

        my $angle2 = (($i + 1) * 2 * $Pi) / $NumSectors;
        my $x7 = 0.20 * sin($angle2);
        my $y7 = 0.20 * cos($angle2);
        my $x8 = 0.30 * sin($angle2);
        my $y8 = 0.30 * cos($angle2);

        this->quad($x5, $y5, $x6, $y6, $x7, $y7, $x8, $y8);

        this->extrude($x6, $y6, $x7, $y7);
        this->extrude($x8, $y8, $x5, $y5);
    }

    glEnd();

    glEndList();
    return $list;
}

sub quad
{
    my ($x1, $y1, $x2, $y2, $x3, $y3, $x4, $y4) = @_;
    this->qglColor(this->trolltechGreen);

    glVertex3d($x1, $y1, -0.05);
    glVertex3d($x2, $y2, -0.05);
    glVertex3d($x3, $y3, -0.05);
    glVertex3d($x4, $y4, -0.05);

    glVertex3d($x4, $y4, +0.05);
    glVertex3d($x3, $y3, +0.05);
    glVertex3d($x2, $y2, +0.05);
    glVertex3d($x1, $y1, +0.05);
}

sub extrude
{
    my ($x1, $y1, $x2, $y2) = @_;
    this->qglColor(this->trolltechGreen->dark(250 + (100 * $x1)));

    glVertex3d($x1, $y1, +0.05);
    glVertex3d($x2, $y2, +0.05);
    glVertex3d($x2, $y2, -0.05);
    glVertex3d($x1, $y1, -0.05);
}

sub normalizeAngle
{
    my ($angle) = @_;
    while ($$angle < 0) {
        $$angle += 360 * 16;
    }
    while ($$angle > 360 * 16) {
        $$angle -= 360 * 16;
    }
}

1;
