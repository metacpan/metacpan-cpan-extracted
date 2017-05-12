use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'Qt',
    'VERSION_FROM' => 'Qt.pm',
    'DIR'	=> [ qw(QAccel
			QApplication
			QBitmap
			QBrush
			QButton
			QButtonGroup
			QCheckBox
			QClipboard
			QColor
			QComboBox
			QCursor
			QDialog
			QEvent
			QFileDialog
			QFont
			QFontInfo
			QFontMetrics
			QFrame
			QGlobal
			QGroupBox
			QImage
			QLCDNumber
			QLabel
			QLayout
			QLineEdit
			QListBox
			QMenuBar
			QMenuData
			QMessageBox
			QMultiLineEdit
			QObject
			QPaintDevice
			QPainter
			QPalette
			QPen
			QPicture
			QPixmap
			QPoint
			QPointArray
			QPopupMenu
			QPrinter
			QPushButton
			QRadioButton
			QRangeControl
			QRect
			QRegion
			QScrollBar
			QSize
			QSlider
			QTabBar
			QTabDialog
			QTableView
			QTimer
			QToolTip
			QWMatrix
			QWidget
			QWindow) ],
);
