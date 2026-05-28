"""Golden fixture: *args and **kwargs."""


class Logger:
    def log(self, level: str, *args: str, **kwargs: int) -> None:
        ...
