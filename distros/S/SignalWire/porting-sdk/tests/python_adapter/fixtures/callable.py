"""Golden fixture: Callable[[A, B], R] parameter."""

from typing import Callable


class Dispatcher:
    def register(
        self,
        name: str,
        handler: Callable[[str, int], bool],
    ) -> None:
        ...
